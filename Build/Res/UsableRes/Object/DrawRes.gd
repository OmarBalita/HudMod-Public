class_name DrawRes extends ObjectRes

@export var drawings_ress: Array[GDDrawingRes]

func _init() -> void:
	set_res_id("Draw")
	set_object_media_type(5)

func get_drawings_ress() -> Array[GDDrawingRes]:
	return drawings_ress

func set_drawings_ress(new_drawings_ress: Array[GDDrawingRes]) -> void:
	drawings_ress = new_drawings_ress


