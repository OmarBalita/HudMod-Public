class_name TimeMarkerRes extends Resource

@export var custom_name: StringName
@export var custom_color: Color = IS.RAINBOW_COLORS[2]
@export_multiline var custom_description: String

func set_custom_name(new_val: StringName) -> void:
	custom_name = new_val

func get_custom_name() -> StringName:
	return custom_name

func set_custom_color(new_val: Color) -> void:
	custom_color = new_val

func get_custom_color() -> Color:
	return custom_color

func set_custom_description(new_val: String) -> void:
	custom_description = new_val

func get_custom_description() -> String:
	return custom_description
