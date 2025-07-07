class_name Layer extends ColorRect

@export var is_locked: bool
@export var is_hided: bool
@export var is_muted: bool

@export_group("Theme")
@export_subgroup("Texture")
@export var texture_lock: Texture2D = preload("res://Asset/Icons/padlock.png")
@export var texture_unlock: Texture2D = preload("res://Asset/Icons/padlock-unlock.png")
@export var texture_hide: Texture2D
@export var texture_show: Texture2D = preload("res://Asset/Icons/eye.png")
@export var texture_mute: Texture2D
@export var texture_unmute: Texture2D = preload("res://Asset/Icons/volume.png")
@export var texture_more: Texture2D = preload("res://Asset/Icons/more.png")


var index = 0


var container: Container
var lock_button: TextureButton
var layer_label: Label
var hide_button: TextureButton
var mute_button: TextureButton
var more_button: TextureButton

var media_clips_root: Control

var displayed_media_clips: Dictionary



# Background Called Functions
# ---------------------------------------------------

func _init(_index: int = 0) -> void:
	index = _index

func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_PASS
	#
	## Start Editor
	#lock_button = InterfaceServer.create_texture_button(texture_unlock)
	#layer_label = InterfaceServer.create_label(str("Layer ", index)); layer_label.custom_minimum_size.x = 100.0
	#hide_button = InterfaceServer.create_texture_button(texture_show)
	#mute_button = InterfaceServer.create_texture_button(texture_unmute)
	#more_button = InterfaceServer.create_texture_button(texture_more)
	container = InterfaceServer.create_box_container()
	#container.set_anchors_preset(Control.PRESET_LEFT_WIDE)
	#container.add_child(InterfaceServer.create_empty_control())
	#container.add_child(lock_button)
	#container.add_child(layer_label)
	#container.add_child(hide_button)
	#container.add_child(mute_button)
	#container.add_child(more_button)
	#container.add_child(InterfaceServer.create_empty_control())
	#add_child(container)
	#
	media_clips_root = InterfaceServer.create_empty_control()
	add_child(media_clips_root)
	#
	# Connections
	ProjectServer.media_clip_added.connect(on_media_clip_changed)
	ProjectServer.media_clip_copied.connect(on_media_clip_changed)
	ProjectServer.media_clip_moved.connect(on_media_clip_changed)
	EditorServer.time_line.timeline_view_changed.connect(update)
	
	# Update
	update()


func _draw() -> void:
	draw_rect(Rect2(Vector2.ZERO, container.size), color.darkened(.2))




# Process Functions
# ---------------------------------------------------



func update() -> void:
	
	var timeline = EditorServer.time_line
	var difference_pos = global_position.x - timeline.global_position.x
	
	var layer = ProjectServer.make_layer_absolute(index)
	for frame_in in layer.media_clips.keys():
		
		var clip_res = layer.media_clips[frame_in]
		
		var clip: MediaClip
		if displayed_media_clips.has(frame_in):
			clip = displayed_media_clips[frame_in]
		else:
			clip = MediaClip.new()
			
			var media_type = MediaServer.get_media_type_from_path(clip_res.media_resource_path)
			var media_clip_info = MediaServer.media_clip_info[media_type]
			clip.color = media_clip_info.bg_color
			clip.add_child(media_clip_info.control.call(clip_res))
			media_clips_root.add_child(clip)
			
			displayed_media_clips[frame_in] = clip
		
		var length = clip_res.length
		var display_begin_pos = timeline.get_display_pos_from_frame(frame_in) - difference_pos
		var display_end_pos = timeline.get_display_pos_from_frame(frame_in + length) - difference_pos
		clip.position.x = display_begin_pos
		clip.size = Vector2(display_end_pos - display_begin_pos, size.y)


# Connections Functions
# ---------------------------------------------------

func on_media_clip_changed(layer_index: int, frame_in: int) -> void:
	if layer_index == index:
		update()
