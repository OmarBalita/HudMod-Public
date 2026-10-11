#############################################################################
##  This file is part of: HudMod Video Editor                              ##
##  https://omar-top.itch.io/hudmod-video-editor                           ##
## ----------------------------------------------------------------------- ##
##  Copyright © 2026 Omar Mohammed Balita, Malek Youssef Elatek.           ##
## ----------------------------------------------------------------------- ##
##  GPLv3                                                                  ##
#############################################################################
@icon("res://Asset/Icons/Objects/render-viewer.png")
class_name RenderViewerClipRes extends Display2DClipRes

@export var render_pass_clip: MediaClipResPath = MediaClipResPath.new_mediares_path(null, &"renderpass_cond"):
	set(val):
		if render_pass_clip: _disconnect_render_pass_clip(render_pass_clip)
		render_pass_clip = val
		if render_pass_clip: _connect_render_pass_clip(render_pass_clip)
		_try_update_texture_from_render_pass()
		_try_update_curr_node_texture()

var texture: ViewportTexture

func get_render_pass_clip() -> MediaClipResPath: return render_pass_clip
func set_render_pass_clip(new_val: MediaClipResPath) -> void: render_pass_clip = new_val

func get_texture() -> ViewportTexture: return texture
func set_texture(new_val: ViewportTexture) -> void: texture = new_val

func _init() -> void:
	_connect_render_pass_clip(render_pass_clip)

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

func _after_process_comps(frame: int) -> void:
	loop_stacked_values(curr_node.set)
	processed.emit()

func exit(node: Node) -> void:
	super(node)

func get_self_main_texture() -> Texture2D: return texture
func get_size(scale: Vector2) -> Vector2:
	var tex: Texture2D = get_self_texture()
	return tex.get_size() * scale if tex else Vector2.ZERO

func build_shader_pipeline(from_loader: bool = false) -> void:
	await super()
	_try_update_curr_node_texture()
	if from_loader: update()


func _try_update_texture_from_render_pass() -> void:
	if render_pass_clip and render_pass_clip.is_valid():
		var viewport: SubViewport = render_pass_clip.get_media_res().get_curr_node()
		texture = viewport.get_texture()
	else:
		texture = null

func _try_update_curr_node_texture() -> void:
	if curr_node: curr_node.texture = get_self_texture()

func _connect_render_pass_clip(path: MediaClipResPath) -> void:
	if not path.media_res_changed.is_connected(_on_render_pass_clip_media_res_changed):
		path.media_res_changed.connect(_on_render_pass_clip_media_res_changed)
	_connect_render_pass(path.media_res)

func _disconnect_render_pass_clip(path: MediaClipResPath) -> void:
	if path.media_res_changed.is_connected(_on_render_pass_clip_media_res_changed):
		path.media_res_changed.disconnect(_on_render_pass_clip_media_res_changed)
	_disconnect_render_pass(path.media_res)

func _connect_render_pass(render_pass: MediaClipRes) -> void:
	if render_pass and not render_pass.viewport_props_updated.is_connected(_on_media_res_viewport_props_updated):
		render_pass.viewport_props_updated.connect(_on_media_res_viewport_props_updated)

func _disconnect_render_pass(render_pass: MediaClipRes) -> void:
	if render_pass and render_pass.viewport_props_updated.is_connected(_on_media_res_viewport_props_updated):
		render_pass.viewport_props_updated.disconnect(_on_media_res_viewport_props_updated)

func _on_render_pass_clip_media_res_changed(old_one: MediaClipRes, new_one: MediaClipRes) -> void:
	_disconnect_render_pass(old_one)
	_connect_render_pass(new_one)
	_try_update_texture_from_render_pass()
	_try_update_curr_node_texture()
	if curr_node and ProjectServer2.is_project_loaded: update()

func _on_media_res_viewport_props_updated() -> void:
	_try_update_texture_from_render_pass()
	_try_update_curr_node_texture()


