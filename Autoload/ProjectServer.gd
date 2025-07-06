extends Node

signal media_clip_added(layer_index: int, frame_in: int)


const EXAMPLE_PATH: String = "res://ExampleProject/"

var project_path: String = EXAMPLE_PATH
var thumbnails_path: String = project_path + "media/thumbnails"
var fortimeline_path: String = project_path + "media/fortimeline"

var aspect_ratio: Vector2
var resolution: Vector2i = Vector2i(1280, 720)
var fps: int = 30:
	set(val):
		fps = val
		delta = 1.0 / fps
var delta: float = 1.0 / fps

var video_length: int

var layers: Dictionary[int, Dictionary]
#layers = {
	#layer_index: {
		#media_clips: {time_x: MediaClipRes.new(), time_y: MediaClipRes.new()},
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
	DirAccess.make_dir_absolute(fortimeline_path)




# Project Layers and Media Clips
# ---------------------------------------------------



func add_media_clip(media_path: String, layer_index: int = -1, frame_in: int = 0) -> void:
	var new_media = MediaClipRes.new()
	var clip_id = generate_clip_id(get_used_clip_id())
	var media_length = EditorServer.editor_default_settings.media_length * fps
	
	if MediaServer.get_media_type_from_path(media_path) in [1, 2]:
		media_length = int(MediaServer.get_audio_duration_with_ffprobe(media_path) * fps)
	new_media.id = clip_id
	new_media.media_resource_path = media_path
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
	
	curr_clips = new_clips
	
	return curr_clips



func remove_layer_clip(layer: int, clip_id: int) -> void:
	var clip_res = layers[layer].media_clips[clip_id]
	Scene.remove_node(layer)


func instance_layer_clip(layer: int, clip_id: int) -> void:
	var clip_res = layers[layer].media_clips[clip_id]
	var media_res_path = clip_res.media_resource_path
	var media_type = MediaServer.get_media_type_from_path(media_res_path)
	if media_type == -1:
		printerr("Project Server: Invalid Instance Layer Clip (Media type could not be recognized).")
		return
	match media_type:
		0: Scene.create_sprite(layer, clip_res, clip_id)
		1: Scene.create_video(layer, clip_res, clip_id)
		2: Scene.create_audio(layer, clip_res, clip_id)





func generate_clip_id(used_id: Array[String], id_length: int = 6) -> String:
	var id_keys = "abcdefghijklmnopqrstuvwxyz"
	var keys_length = id_keys.length() - 1
	
	var result_id: String
	
	while not result_id or result_id in used_id:
		result_id = ""
		for time in id_length:
			result_id += id_keys[randi_range(0, keys_length)]
	
	return result_id


func get_used_clip_id() -> Array[String]:
	var used_clip_id: Array[String]
	for layer_index in layers:
		var clips = layers[layer_index].media_clips
		for time_begin in clips:
			used_clip_id.append(clips[time_begin].id)
	return used_clip_id






# Files and Saving Part
# ---------------------------------------------------


func get_res_file(path: String, as_file: Resource) -> Resource:
	var full_path = project_path + path
	DirAccess.make_dir_absolute(full_path.get_base_dir())
	if not FileAccess.file_exists(full_path):
		ResourceSaver.save(as_file, full_path)
	return ResourceLoader.load(full_path)








