#############################################################################
##  This file is part of: HudMod Video Editor                              ##
##  https://omar-top.itch.io/hudmod-video-editor                           ##
## ----------------------------------------------------------------------- ##
##  Copyright © 2026 Omar Mohammed Balita.                                 ##
## ----------------------------------------------------------------------- ##
## GPLv3                                                                   ##
#############################################################################
@icon("res://Asset/Icons/Objects/image.png")
class_name ImageClipRes extends Display2DClipRes

@export var image: String:
	set(val):
		image = val
		if curr_node:
			curr_node.texture = get_self_texture()

func _get_exported_props() -> Dictionary[StringName, Dictionary]:
	return {&"image": export(string_args(image))} as Dictionary[StringName, Dictionary].merged(super())

func init_node(root_layer_idx: int, layer_idx: int, layer_res: LayerRes, frame: int) -> Node:
	var image_viewer:= ImageViewer.new()
	return _init_node2d(root_layer_idx, layer_idx, layer_res, frame, image_viewer)

func enter(node: Node) -> void:
	super(node)
	if ppr: await process_passes_materials(1.)
	node.texture = get_self_texture()

func get_display_name() -> String: return str("Image:", image.get_file())
func get_thumbnail() -> Texture2D: return MediaServer.get_thumbnail(image).texture
static func get_icon() -> Texture2D: return preload("res://Asset/Icons/Objects/image.png")

static func get_media_clip_info() -> Dictionary[StringName, String]: return {
	&"title": "Image",
	&"description": ""
}

func get_self_main_texture() -> Texture2D: return MediaCache.get_texture(image)
func get_size(scale: Vector2) -> Vector2:
	var tex: Texture2D = get_self_texture()
	return tex.get_size() * curr_node.scale_factor * scale if tex else Vector2.ZERO

func build_shader_pipeline() -> void:
	await super()
	if ppr: await process_passes_materials(1.)
	if curr_node: curr_node.texture = get_self_texture()
	update()

func check_for_paths(paths_for_check: PackedStringArray) -> PackedStringArray:
	return [] if paths_for_check.has(image) else [image]

func format_paths(paths_for_format: Dictionary[String, String]) -> void:
	if paths_for_format.has(image): image = paths_for_format[image]

func erase_paths(paths_for_erase: PackedStringArray) -> void:
	if paths_for_erase.has(image): image = ""

func update_paths() -> void:
	image = image
