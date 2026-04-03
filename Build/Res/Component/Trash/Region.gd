class_name CompRegion extends ComponentRes

@export var enable_region: bool
@export var position: Vector2
@export var size: Vector2

var region_rect: Rect2

func set_owner(new_owner: MediaClipRes) -> void:
	super(new_owner)
	if new_owner:
		var tex: Texture2D = new_owner.get_self_main_texture()
		position = Vector2.ZERO
		size = Vector2(tex.get_size())
		update_region_rect()

func update_region_rect() -> void:
	region_rect = Rect2(
		position,
		size
	)

func _get_exported_props() -> Dictionary[StringName, ExportInfo]:
	var ui_cond: Array = [get.bind(&"enable_region"), [true]]
	return {
		&"enable_region": export(bool_args(enable_region)),
		&"position": export(vec2_args(position), ui_cond),
		&"size": export(vec2_args(size), ui_cond)
	}

func _process(frame: int) -> void:
	submit_stacked_value_with_custom_method(&"region_enabled", enable_region, MethodType.SET)
	if enable_region: submit_stacked_value_with_custom_method(&"region_rect", Rect2(position, size), MethodType.SET)

