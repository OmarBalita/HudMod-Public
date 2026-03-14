@icon("res://Asset/Icons/Objects/shape-2d.png")
class_name Shape2DClipRes extends Display2DClipRes

@export var draw_comps: Array[DrawShapeComponentRes] = []

static func get_media_clip_info() -> Dictionary[StringName, String]:
	return {
	&"title": "Shape2D",
	&"description": ""
}

func get_draw_comps() -> Array[DrawShapeComponentRes]: return draw_comps
func set_draw_comps(new_val: Array[DrawShapeComponentRes]) -> void: draw_comps = new_val

func init_node(layer_idx: int, frame_in: int) -> Node:
	var shape_2d:= Shape2DObject.new()
	shape_2d.draw_shape_comps = draw_comps
	return shape_2d

func _process_comps(frame: int) -> void:
	super(frame)
	for draw_comp: DrawShapeComponentRes in draw_comps:
		if draw_comp.dirty_level:
			curr_node.queue_redraw()
			break
	for draw_comp: DrawShapeComponentRes in draw_comps:
		draw_comp.min_dirty()

func _emit_media_clip_res_updated(_from: int = -1, _length: int = -1) -> void:
	super(_from, _length)
	draw_comps.clear()
	for comp: ComponentRes in components.Display2D:
		if comp is not DrawShapeComponentRes or not comp.enabled:
			continue
		draw_comps.append(comp)
	if curr_node:
		curr_node.queue_redraw()


