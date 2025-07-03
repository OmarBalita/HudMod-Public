extends Node

signal media_clip_added(layer_index: int, frame_in: int)
signal curr_clips_changed(removed_clips: Dictionary[int, int], added_clips: Dictionary[int, int])


const EXAMPLE_PATH: String = "res://ExampleProject/"

var project_path: String = EXAMPLE_PATH
var thumbnails_path: String = project_path + "media/thumbnails"

var aspect_ratio: Vector2
var resolution: Vector2
var fps: int = 30:
	set(val):
		fps = val
		delta = 1.0 / fps
var delta: float = 1.0 / fps

var video_length: int

var layers: Dictionary[int, Dictionary]
#layers = {
	#layer_index: {
		#media_clips: [time_x: MediaClipRes.new(), time_y: MediaClipRes.new()],
		#loked: bool(),
		#hided: bool(),
		#muted: bool()
	#}
#}

var curr_clips: Dictionary[int, int] # key is layer, val is (clip_id or time_begin)


var project_res: ProjectRes = ProjectRes.new()



# Background Called Functions
# ---------------------------------------------------




func _ready() -> void:
	DirAccess.make_dir_absolute(thumbnails_path)

func _input(event: InputEvent) -> void:
	if event is InputEventKey:
		if event.keycode == KEY_ENTER and event.is_pressed():
			add_media_clip(-1, EditorServer.time_line.curr_frame)



# Project Layers and Media Clips
# ---------------------------------------------------



func add_media_clip(layer_index: int = -1, frame_in: int = 0) -> void:
	var new_media = MediaClipRes.new()
	var media_length = EditorServer.editor_default_settings.media_length * fps
	new_media.length = media_length
	if layer_index < 0 or not is_layer_unoccupied(layer_index, frame_in, media_length):
		layer_index = get_best_unoccupied_layer(frame_in, media_length)
	layers[layer_index].media_clips[frame_in] = new_media
	media_clip_added.emit(layer_index, frame_in)
	update_curr_clips()


func get_best_unoccupied_layer(frame_in: int, media_length: int) -> int:
	var layer_index = 0
	while true:
		if is_layer_unoccupied(layer_index, frame_in, media_length):
			break
		layer_index += 1
	return layer_index

func is_layer_unoccupied(layer_index: int, frame_in: int, media_length: int) -> bool:
	
	var layer = make_layer_absolute(layer_index)
	var media_clips = layer.media_clips
	
	var new_time_begin = frame_in
	var new_time_end = frame_in + media_length
	
	for time_begin: int in media_clips.keys():
		var media = media_clips.get(time_begin)
		var time_end = time_begin + media.length
		if not (time_end <= new_time_begin or new_time_end <= time_begin):
			return false
	return true


func make_layer_absolute(layer_index: int) -> Dictionary:
	if not layers.has(layer_index):
		layers[layer_index] = {
			media_clips = {},
			locked = false,
			hided = false,
			muted = false
		}
	return layers[layer_index]




func update_curr_clips(curr_frame: int = -1) -> Dictionary[int, int]:
	
	var new_clips: Dictionary[int, int]
	
	if curr_frame < 0:
		curr_frame = EditorServer.time_line.curr_frame
	
	for layer_index in layers.keys():
		var media_clips = layers[layer_index].media_clips
		for time_begin: int in media_clips.keys():
			var media = media_clips.get(time_begin)
			var time_end = time_begin + media.length
			if curr_frame >= time_begin and curr_frame < time_end:
				new_clips[layer_index] = time_begin
				break
	
	var removed_clips: Dictionary[int, int]
	var added_clips: Dictionary[int, int]
	
	for index in curr_clips.keys():
		var curr_clip_id = curr_clips[index]
		if new_clips.has(index) and curr_clip_id == new_clips[index]:
			continue
		removed_clips[index] = curr_clip_id
		remove_layer_clip(index, curr_clip_id)
	
	for index in new_clips.keys():
		var new_clip_id = new_clips[index]
		if curr_clips.has(index) and new_clip_id == curr_clips[index]:
			continue
		added_clips[index] = new_clip_id
		instance_layer_clip(index, new_clip_id)
	
	curr_clips_changed.emit(removed_clips, added_clips)
	curr_clips = new_clips
	
	return curr_clips



func remove_layer_clip(layer: int, clip_id: int) -> void:
	var clip_res = layers[layer].media_clips[clip_id]
	var clip_nodes_explorer = EditorServer.clip_nodes_explorer
	clip_nodes_explorer.remove_layer_node(layer, clip_res)


func instance_layer_clip(layer: int, clip_id: int) -> void:
	var clip_res = layers[layer].media_clips[clip_id]
	var clip_nodes_explorer = EditorServer.clip_nodes_explorer
	clip_nodes_explorer.create_layer_node(layer, clip_res)





# Files and Saving Part
# ---------------------------------------------------


func get_res_file(path: String, as_file: Resource) -> Resource:
	var full_path = project_path + path
	DirAccess.make_dir_absolute(full_path.get_base_dir())
	if not FileAccess.file_exists(full_path):
		ResourceSaver.save(as_file, full_path)
	return ResourceLoader.load(full_path)








