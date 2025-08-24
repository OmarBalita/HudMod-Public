class_name CheckGroup extends Resource

@export var checked_index: int
@export var save_path: String

func get_checked_index() -> int:
	return checked_index

func set_checked_index(_checked_index: int) -> void:
	checked_index = _checked_index

func get_save_path() -> String:
	return save_path

func set_save_path(_save_path: String) -> void:
	save_path = _save_path

