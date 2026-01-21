#class_name DrawRes extends Object2DRes
#
#@export var drawings_ress: Array[GDDrawingRes]
#
#func instance_object(parent_res: MediaClipRes, media_res: MediaClipRes, layer_index: int, frame_in: int, root_layer_index: int) -> Node:
	#var draw:= GDDraw.new()
	#Scene2.instance_object_2d(parent_res, media_res, draw, layer_index, frame_in, root_layer_index)
	#return draw
#
#func get_drawings_ress() -> Array[GDDrawingRes]:
	#return drawings_ress
#
#func set_drawings_ress(new_drawings_ress: Array[GDDrawingRes]) -> void:
	#drawings_ress = new_drawings_ress
#
#static func get_object_info() -> Dictionary[StringName, String]:
	#return {&"title": "Draw",
		#&"description": "Draw has professional vector drawing tools.
		#You can draw, animate, and use an advanced brush building system."}
