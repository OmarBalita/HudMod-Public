@icon("res://Asset/Icons/Objects/camera-2d.png")
class_name Camera2DRes extends Object2DRes

enum AnchorMode {
	TOP_LEFT,
	CENTER
}

@export var camera_enabled: bool = true
@export var offset: Vector2
@export var anchor_mode: AnchorMode = 1
@export var ignore_rotation: bool = true
@export var zoom: Vector2 = Vector2.ONE

func instance_object(parent_res: MediaClipRes, media_res: MediaClipRes, layer_index: int, frame_in: int, root_layer_index: int) -> Node:
	var camera_2d: Camera2D = Camera2D.new()
	Scene2.instance_object_2d(parent_res, media_res, camera_2d, layer_index, frame_in, root_layer_index)
	return camera_2d

static func get_object_info() -> Dictionary[StringName, String]:
	return {&"title": "Camera2D",
		&"description": "Camera2D can be a game changer for the editor,
		allowing you to add a camera clip with different properties to any part of the timeline you want."}

static func get_object_section() -> StringName: return &"Camera"

func _enter() -> void: Scene2.add_camera_as_object(owner.curr_node)
func _exit() -> void: Scene2.remove_camera_as_object(owner.curr_node)

func _get_exported_props() -> Dictionary[StringName, ExportInfo]:
	return {
		&"camera_enabled": export(bool_args(camera_enabled)),
		&"offset": export(vec2_args(offset)),
		&"anchor_mode": export(options_args(anchor_mode, AnchorMode)),
		&"ignore_rotation": export(bool_args(ignore_rotation)),
		&"zoom": export(vec2_args(zoom))
	}

func _process(frame: int) -> void:
	submit_stacked_value_with_custom_method(&"enabled", camera_enabled)
	submit_stacked_value(&"offset", offset)
	submit_stacked_value_with_custom_method(&"anchor_mode", anchor_mode)
	submit_stacked_value_with_custom_method(&"ignore_rotation", ignore_rotation)
	if zoom.x != .0 and zoom.y != .0:
		submit_stacked_value(&"zoom", zoom)


