@icon("res://Asset/Icons/Objects/image.png")
class_name ImageClipRes extends Display2DClipRes

@export var image: String:
	set(val):
		image = val
		if curr_node:
			curr_node.texture = get_self_texture()
		update()


static func get_media_clip_info() -> Dictionary[StringName, String]: return {
	&"title": "Image",
	&"description": ""
}

func _get_exported_props() -> Dictionary[StringName, ExportInfo]:
	return {&"image": export(string_args(image))} as Dictionary[StringName, ExportInfo].merged(super())

func init_node(root_layer_idx: int, layer_idx: int, layer_res: LayerRes, frame: int) -> Node:
	var image_viewer:= ImageViewer.new()
	return _init_node2d(root_layer_idx, layer_idx, layer_res, frame, image_viewer)

func enter(node: Node) -> void:
	super(node)
	node.texture = get_self_texture()

func get_display_name() -> String: return str("Image:", image.get_file())
func get_thumbnail() -> Texture2D: return MediaServer.get_thumbnail(image).texture

func get_self_main_texture() -> Texture2D: return MediaCache.get_texture(image)

func build_shader_pipeline() -> void:
	await super()
	if curr_node:
		curr_node.texture = get_self_texture()
		process_here()

func check_for_paths(paths_for_check: PackedStringArray) -> PackedStringArray:
	return [] if paths_for_check.has(image) else [image]

func format_paths(paths_for_format: Dictionary[String, String]) -> void:
	if paths_for_format.has(image): image = paths_for_format[image]

func erase_paths(paths_for_erase: PackedStringArray) -> void:
	if paths_for_erase.has(image): image = ""

func update_paths() -> void:
	image = image
