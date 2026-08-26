#############################################################################
##  This file is part of: HudMod Video Editor                              ##
##  https://omar-top.itch.io/hudmod-video-editor                           ##
## ----------------------------------------------------------------------- ##
##  Copyright © 2026 Omar Mohammed Balita.                                 ##
## ----------------------------------------------------------------------- ##
## GPLv3                                                                   ##
#############################################################################
@icon("res://Asset/Icons/Objects/render-pass.png")
class_name RenderPassClipRes extends MediaClipRes

signal viewport_props_updated()

@export var size: Vector2 = Vector2(512., 512.)
@export var transparent_background: bool = true
@export var enable_audio: bool

func get_size() -> Vector2: return size
func set_size(new_val: Vector2) -> void: size = new_val

func get_transparent_background() -> bool: return transparent_background
func set_transparent_background(new_val: bool) -> void: transparent_background = new_val

func get_enable_audio() -> bool: return enable_audio
func set_enable_audio(new_val: bool) -> void: enable_audio = new_val

func set_prop_and_emit(property_key: StringName, property_val: Variant) -> void:
	super(property_key, property_val)
	if curr_node: _update_viewport_props()

static func get_media_clip_info() -> Dictionary[StringName, String]:
	return {
	&"title": "RenderPass",
	&"description": ""
}

static func get_properties_section() -> StringName: return &"RenderPass"
static func get_icon() -> Texture2D: return preload("res://Asset/Icons/Objects/render-pass.png")

func _get_exported_props() -> Dictionary[StringName, Dictionary]:
	return {
		&"size": export(vec2_args(size, true), [], false),
		&"transparent_background": export(bool_args(transparent_background), [], false),
		&"enable_audio": export(bool_args(enable_audio))
	}

func init_node(root_layer_idx: int, layer_idx: int, layer_res: LayerRes, frame: int) -> Node:
	var subviewport:= SubViewport.new()
	subviewport.render_target_update_mode = SubViewport.UPDATE_ONCE
	subviewport.add_child(Camera2D.new())
	return subviewport

func enter(node: Node) -> void:
	super(node)
	_update_viewport_props()

func process(frame: int) -> void:
	curr_node.render_target_update_mode = SubViewport.UPDATE_ONCE
	await RenderingServer.frame_post_draw
	super(frame)


func _update_viewport_props() -> void:
	curr_node.size = size
	curr_node.transparent_bg = transparent_background
	curr_node.audio_listener_enable_2d = enable_audio
	await RenderingServer.frame_post_draw
	curr_node.render_target_update_mode = SubViewport.UPDATE_ONCE
	viewport_props_updated.emit()


