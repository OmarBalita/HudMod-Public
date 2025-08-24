class_name UIProfile extends Resource

signal ui_visiblity_updated()

@export var ui_conditions: Dictionary[Array, Array]

func get_ui_conditions() -> Dictionary[Array, Array]:
	return ui_conditions

func set_ui_conditions(new_ui_conditions: Dictionary[Array, Array]) -> void:
	ui_conditions = new_ui_conditions

func add_ui_condition(ui_condition: Dictionary[Array, Array]) -> void:
	ui_conditions.merge(ui_condition)

func update() -> void:
	var conditions_buffer: Dictionary[Callable, Variant]
	
	for key: Array in ui_conditions.keys():
		var cond_func = key[0]
		var needed_results = key[1]
		
		if cond_func is not Callable:
			printerr("the First Element of \"ui_condition\" Key must be \"Callable\"")
			return
		
		var ui_objects: Array = ui_conditions[key]
		
		var cond_result: Variant = null
		
		if conditions_buffer.has(cond_func):
			cond_result = conditions_buffer.get(cond_func)
		else:
			cond_result = cond_func.call()
		
		var is_accepted: bool = cond_result in needed_results
		
		for ui_object: Node in ui_objects:
			if ui_object is Control: ui_object.visible = is_accepted
			elif ui_object is ShortcutNode: ui_object.enabled = is_accepted



