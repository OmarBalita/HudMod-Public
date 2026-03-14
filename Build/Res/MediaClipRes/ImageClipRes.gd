@icon("res://Asset/Icons/Objects/image.png")
class_name ImageClipRes extends Display2DClipRes

@export var image: String:
	set(val):
		image = val
		if curr_node:
			curr_node.texture = get_self_main_texture()
		update()

static func get_media_clip_info() -> Dictionary[StringName, String]: return {
	&"title": "Image",
	&"description": ""
}

func _get_exported_props() -> Dictionary[StringName, ExportInfo]:
	return {&"image": export(string_args(image))} as Dictionary[StringName, ExportInfo].merged(super())

func init_node(layer_idx: int, frame_in: int) -> Node:
	var sprite: Sprite2D = Sprite2D.new()
	sprite.texture = get_self_main_texture()
	return sprite

func _process_comps(frame: int) -> void:
	super(frame)

func get_display_name() -> String: return str("Image:", image.get_file())
func get_thumbnail() -> Texture2D: return MediaServer.get_thumbnail(image).texture

func get_self_main_texture() -> Texture2D: return MediaCache.get_texture(image)
