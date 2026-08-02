@icon("res://Asset/Icons/Objects/render-pass.png")
class_name RenderPassClipRes extends MediaClipRes

static func get_media_clip_info() -> Dictionary[StringName, String]:
	return {
	&"title": "RenderPass",
	&"description": ""
}

static func get_properties_section() -> StringName: return &"RenderPass"
static func get_icon() -> Texture2D: return preload("res://Asset/Icons/Objects/render-pass.png")

func init_node(root_layer_idx: int, layer_idx: int, layer_res: LayerRes, frame: int) -> Node:
	var subviewport:= SubViewport.new()
	subviewport.render_target_update_mode = SubViewport.UPDATE_ONCE
	subviewport.audio_listener_enable_2d = true
	subviewport.transparent_bg = true
	return subviewport

func process(frame: int) -> void:
	curr_node.render_target_update_mode = SubViewport.UPDATE_ONCE
	super(frame)
