#############################################################################
##  This file is part of: HudMod Video Editor                              ##
##  https://omar-top.itch.io/hudmod-video-editor                           ##
## ----------------------------------------------------------------------- ##
##  Copyright © 2026 Omar Mohammed Balita.                                 ##
## ----------------------------------------------------------------------- ##
## GPLv3                                                                   ##
#############################################################################
@icon("res://Asset/Icons/Objects/camera-2d.png")
class_name Camera2DClipRes extends Display2DClipRes

enum AnchorMode {
	TOP_LEFT,
	CENTER
}

@export var camera_enabled: bool = true
@export var offset: Vector2
@export var anchor_mode: AnchorMode = 1
@export var ignore_rotation: bool = true
@export var zoom: Vector2 = Vector2.ONE

static func get_media_clip_info() -> Dictionary[StringName, String]:
	return {
	&"title": "Camera2D",
	&"description": ""
}

static func get_icon() -> Texture2D: return preload("res://Asset/Icons/Objects/camera-2d.png")

func _get_exported_props() -> Dictionary[StringName, ExportInfo]:
	return {
		&"camera_enabled": export(bool_args(camera_enabled)),
		&"offset": export(vec2_args(offset)),
		&"anchor_mode": export(options_args(anchor_mode, AnchorMode)),
		&"ignore_rotation": export(bool_args(ignore_rotation)),
		&"zoom": export(vec2_args(zoom))
	} as Dictionary[StringName, ExportInfo].merged(super())

func init_node(root_layer_idx: int, layer_idx: int, layer_res: LayerRes, frame: int) -> Node:
	return _init_node2d(root_layer_idx, layer_idx, layer_res, frame, Camera2D.new())

func enter(node: Node) -> void:
	super(node)
	Scene2.add_camera(self)

func _process_comps(frame: int) -> void:
	curr_node.enabled = camera_enabled
	curr_node.offset = offset
	curr_node.anchor_mode = anchor_mode
	curr_node.ignore_rotation = ignore_rotation
	if zoom.x != .0 and zoom.y != .0:
		curr_node.zoom = zoom
	super(frame)

func exit(node: Node) -> void:
	super(node)
	Scene2.remove_camera(self)

