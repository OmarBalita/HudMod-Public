class_name ShortcutInfo extends Resource

@export var name: StringName
@export var function: Callable

func _init(_name: StringName, _function: Callable) -> void:
	name = _name
	function = _function
