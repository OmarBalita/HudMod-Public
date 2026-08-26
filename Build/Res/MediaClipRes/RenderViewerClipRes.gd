#############################################################################
##  This file is part of: HudMod Video Editor                              ##
##  https://omar-top.itch.io/hudmod-video-editor                           ##
## ----------------------------------------------------------------------- ##
##  Copyright © 2026 Omar Mohammed Balita.                                 ##
## ----------------------------------------------------------------------- ##
## GPLv3                                                                   ##
#############################################################################
@icon("res://Asset/Icons/Objects/render-viewer.png")
class_name RenderViewerClipRes extends Display2DClipRes

@export var render_pass_clip: MediaClipResPath = MediaClipResPath.new_mediares_path(MediaClipResPath.renderpass_cond):
	set(val):
		render_pass_clip = val
		_init_render_pass_clip()

var texture: ViewportTexture

func get_render_pass_clip() -> MediaClipResPath: return render_pass_clip
func set_render_pass_clip(new_val: MediaClipResPath) -> void: render_pass_clip = new_val

func get_texture() -> ViewportTexture: return texture
func set_texture(new_val: ViewportTexture) -> void: texture = new_val

func _init() -> void:
	_init_render_pass_clip()

static func get_media_clip_info() -> Dictionary[StringName, String]:
	return {
	&"title": "RenderViewer",
	&"description": ""
}

static func get_icon() -> Texture2D:
	return preload("res://Asset/Icons/Objects/render-viewer.png")

func _get_exported_props() -> Dictionary[StringName, Dictionary]:
	return super().merged({&"render_pass_clip": export([render_pass_clip])})



func init_node(root_layer_idx: int, layer_idx: int, layer_res: LayerRes, frame: int) -> Node:
	var fixed_viewer:= FixedViewer.new()
	_try_update_texture_from_render_pass()
	return fixed_viewer

func enter(node: Node) -> void:
	super(node)
	node.texture = get_self_texture()

func process(frame: int) -> void:
	super(frame)
	await RenderingServer.frame_post_draw
	curr_node.queue_redraw()

func exit(node: Node) -> void:
	super(node)

func get_self_main_texture() -> Texture2D: return texture
func get_size(scale: Vector2) -> Vector2:
	var tex: Texture2D = get_self_texture()
	return tex.get_size() * scale if tex else Vector2.ZERO

func build_shader_pipeline() -> void:
	await super()
	if curr_node:
		curr_node.texture = get_self_texture()
		process_here()


func _try_update_texture_from_render_pass() -> void:
	if render_pass_clip.is_valid():
		var viewport: SubViewport = render_pass_clip.get_media_res().get_curr_node()
		texture = viewport.get_texture()
	else:
		texture = null

func _try_update_curr_node_texture() -> void:
	if curr_node: curr_node.texture = get_self_texture()


func _init_render_pass_clip() -> void:
	_try_update_texture_from_render_pass()
	_try_update_curr_node_texture()
	render_pass_clip.media_res_changed.connect(_on_render_pass_clip_media_res_changed)

func _on_render_pass_clip_media_res_changed(old_one: MediaClipRes, new_one: MediaClipRes) -> void:
	if old_one: old_one.viewport_props_updated.disconnect(_on_media_res_viewport_props_updated)
	if new_one: new_one.viewport_props_updated.connect(_on_media_res_viewport_props_updated)
	_try_update_texture_from_render_pass()
	_try_update_curr_node_texture()

func _on_media_res_viewport_props_updated() -> void:
	_try_update_texture_from_render_pass()
	_try_update_curr_node_texture()


