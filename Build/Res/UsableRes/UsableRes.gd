class_name UsableRes extends Resource

signal res_changed()

@export var properties: Dictionary[StringName, Dictionary] = {}
# {&"property": {"v": Variant(), "s": Callable(), "g": Callable()}}
@export var use_global_variables_as_properties: bool = true:
	set(val):
		use_global_variables_as_properties = val
		if val:
			get_prop_func = get
			set_prop_func = set
		else:
			get_prop_func = _get_prop
			set_prop_func = _set_prop

var get_prop_func: Callable = get
var set_prop_func: Callable = set

func _get_prop_default(property_key: StringName) -> Variant:
	return properties[property_key].v

func _set_prop_default(property_key: StringName, property_val: Variant) -> void:
	properties[property_key].v = property_val

func _get_prop(property_key: StringName) -> Variant:
	return call(properties[property_key].g, property_key)

func _set_prop(property_key: StringName, property_val: Variant) -> void:
	call(properties[property_key].s, property_key, property_val)

func get_prop(property_key: StringName) -> Variant:
	return get_prop_func.call(property_key)

func set_prop(property_key: StringName, property_val: Variant) -> void:
	set_prop_func.call(property_key, property_val)

func set_and_emit_prop(property_key: StringName, property_val: Variant) -> void:
	set_prop_func.call(property_key, property_val)
	res_changed.emit()

func register_prop(property_key: StringName, property_val: Variant, set_func: StringName = &"_set_prop_default", get_func: StringName = &"_get_prop_default") -> void:
	properties[property_key] = {"v": property_val, "s": set_func, "g": get_func}

func register_props(_properties: Dictionary[StringName, Variant], set_func: StringName = &"_set_prop_default", get_func: StringName = &"_get_prop_default") -> void:
	for property_key: StringName in _properties:
		var property_default_val: Variant = _properties.get(property_key)
		register_prop(property_key, property_default_val, set_func, get_func)

func loop_prop(method: Callable) -> void:
	for property_name: StringName in properties:
		var property_val: Variant = get_prop(property_name)
		method.call(property_name, property_val)

func _get_exported_props() -> Dictionary[StringName, ExportInfo]:
	return {}

func _exported_props_controllers_created(props_controllers: Dictionary[StringName, IS.EditBoxContainer]) -> void:
	pass

func _send_new_val(edit_box_container: IS.EditBoxContainer, usable_res: UsableRes, prop_key: StringName, prop_new_val: Variant) -> void:
	edit_box_container.val_changed.emit(usable_res, prop_key, prop_new_val)

func _send_keyframe(edit_box_container: IS.EditBoxContainer, usable_res: UsableRes, param_key: StringName, param_new_val: Variant) -> void:
	edit_box_container.keyframe_sended.emit(usable_res, param_key, param_new_val)

static func create_custom_edit(name: String, usable_res: UsableRes, usable_ress: Array[UsableRes] = []) -> Array[Control]:
	var usable_res_script:= usable_res.get_script() as Script
	
	if not usable_ress.has(usable_res):
		usable_ress.append(usable_res)
	
	var exported_props: Dictionary[StringName, ExportInfo] = usable_res._get_exported_props()
	
	var edits_box_container: BoxContainer = IS.create_box_container(8, true)
	var categories_entered: Array[Category]
	var curr_box_container: BoxContainer = edits_box_container
	
	var edit_box_container: BoxContainer = IS.create_custom_edit_box(name, edits_box_container)
	edits_box_container.set_meta(&"owner", edit_box_container)
	
	var properties_controllers: Dictionary[StringName, IS.EditBoxContainer] = {}
	EditorServer.set_usable_res_controllers(usable_res, usable_ress, edit_box_container, properties_controllers)
	
	var ui_profile: UIProfile = UIProfile.new()
	var ui_conditions: Dictionary[Array, Array]
	
	for key: StringName in exported_props:
		var ctrlr_info: ExportInfo = exported_props[key]
		var ctrlr_args: Array = ctrlr_info.get_args()
		var ui_cond: Array = ctrlr_info.get_ui_cond()
		
		if ctrlr_info is ExportMethodInfo:
			
			match ctrlr_info.get_method_type():
				
				ExportMethodType.METHOD_ENTER_CATEGORY:
					var cat_color: Color = ctrlr_args[0] if ctrlr_args.size() else Color.TRANSPARENT
					var cat: Category = IS.create_category(true, key, cat_color, Vector2.ZERO, false)
					cat.content_color = Color.from_hsv(.6 + categories_entered.size() * .2, .6, .6, .5)
					curr_box_container.add_child(cat)
					categories_entered.append(cat)
					curr_box_container = cat.content_container
				
				ExportMethodType.METHOD_EXIT_CATEGORY:
					categories_entered.resize(categories_entered.size() - 1)
					curr_box_container = categories_entered.back().content_container if categories_entered.size() else edits_box_container
				
				ExportMethodType.METHOD_CALLABLE:
					var callable_button: Button = IS.create_button(key, IS.TEXTURE_MEGAPHONE, true)
					callable_button.pressed.connect(ctrlr_args[0])
					curr_box_container.add_child(callable_button)
				
				ExportMethodType.METHOD_CUSTOM_EXPORT:
					pass
		
		else:
			var val: Variant = ctrlr_args[0]
			
			var controllers: Array[Control] = ClassServer.create_prop_editor(key, val, ctrlr_args)
			if controllers.size():
				var edit_box: IS.EditBoxContainer = IS.get_edit_box_from(controllers)
				var is_object: bool = typeof(val) == TYPE_OBJECT
				var changeable: bool = not is_object
				
				edit_box.default_val = usable_res_script.get_property_default_value(key)
				edit_box.keyframable = changeable
				edit_box.resetable = changeable
				edit_box.set_curr_val(val)
				properties_controllers[key] = edit_box
				
				edit_box.val_changed.connect(
					func(prop_usable_res: UsableRes, prop_key: StringName, new_val: Variant) -> void:
						if prop_usable_res == null: prop_usable_res = usable_res
						if prop_key.is_empty(): prop_key = key
						for curr_usable_res: UsableRes in usable_ress:
							curr_usable_res.set_and_emit_prop(prop_key, new_val)
							curr_usable_res._send_new_val(edit_box_container, curr_usable_res, prop_key, new_val)
						edit_box.update_ui()
						ui_profile.update()
				)
				
				edit_box.keyframe_sended.connect(
					func(prop_usable_res: UsableRes, prop_key: StringName, prop_new_val: Variant) -> void:
						if prop_usable_res == null: prop_usable_res = usable_res
						if prop_key.is_empty(): prop_key = key
						#usable_res.send_keyframe(edit_box_container, prop_usable_res, prop_key, prop_new_val)
						for curr_usable_res: UsableRes in usable_ress:
							curr_usable_res._send_keyframe(edit_box_container, curr_usable_res, prop_key, prop_new_val)
				)
				curr_box_container.add_child(edit_box)
				
				if ui_cond:
					if ui_conditions.has(ui_cond): ui_conditions[ui_cond].append(edit_box)
					else: ui_conditions[ui_cond] = [edit_box]
	
	usable_res._exported_props_controllers_created(properties_controllers)
	
	ui_profile.set_ui_conditions(ui_conditions)
	ui_profile.update()
	
	return [edits_box_container]

static func _is_method_key(key: StringName) -> bool:
	return key.begins_with("[") and key.ends_with("]")

func get_classname() -> StringName:
	return get_script().get_global_name()


class ExportInfo extends RefCounted:
	@export var args: Array
	@export var ui_cond: Array
	
	func _init(_args: Array, _ui_cond: Array = []) -> void:
		args = _args
		ui_cond = _ui_cond
	
	func get_args() -> Array: return args
	func set_args(new_val: Array) -> void: args = new_val
	func get_ui_cond() -> Array: return ui_cond
	func set_ui_cond(new_val: Array) -> void: ui_cond = new_val

enum ExportMethodType {
	METHOD_ENTER_CATEGORY,
	METHOD_EXIT_CATEGORY,
	METHOD_CALLABLE,
	METHOD_CUSTOM_EXPORT
}

class ExportMethodInfo extends ExportInfo:
	@export var method_type: ExportMethodType
	
	func _init(_args: Array, _ui_cond: Array = [], _method_type: ExportMethodType = 0) -> void:
		super(_args, _ui_cond)
		method_type = _method_type
	
	func get_method_type() -> ExportMethodType: return method_type
	func set_method_type(new_val: ExportMethodType) -> void: method_type = new_val


static func export(args: Array, ui_cond: Array = []) -> ExportInfo: return ExportInfo.new(args, ui_cond)

static func export_method(method_type: ExportMethodType, args: Array = [], ui_cond: Array = []) -> ExportMethodInfo:
	return ExportMethodInfo.new(args, ui_cond, method_type)

static func bool_args(val: bool) -> Array: return [val]
static func string_args(val: String, controller_type: IS.StringControllerType = 0, open_extensions: Array[String] = [], placeholder: String = "") -> Array: return [val, placeholder, controller_type, open_extensions]
static func int_args(val: int, min: float = -INF, max: float = INF, step: int = 1, spin_scale: int = 1, magnet_step: int = 5, controller_type: IS.FloatControllerType = 0) -> Array: return [val, min, max, step, spin_scale, magnet_step, true, controller_type]
static func options_args(val: int, options: Dictionary) -> Array: return [val, -INF, INF, 1, 1, 1, true, IS.FloatControllerType.TYPE_OPTIONS, options]
static func float_args(val: float, min: float = -INF, max: float = INF, step: float = .01, spin_scale: float = .01, magnet_step: float = 5., controller_type: IS.FloatControllerType = 0) -> Array: return [val, min, max, step, spin_scale, magnet_step, false, controller_type]
static func vec2_args(val: Vector2) -> Array: return [val]
static func vec3_args(val: Vector3) -> Array: return [val]
static func color_args(val: Color) -> Array: return [val]
static func list_args(val: Array, list_classname: StringName, can_add_element: bool = true, can_remove_element: bool = true,
	can_duplicate_element: bool = true, can_change_element_priority: bool = true, min_elements_count: int = 0) -> Array:
	return [val, list_classname, can_add_element, can_remove_element, can_duplicate_element, can_change_element_priority, min_elements_count]

static func method_enter_cat_args(cat_color: Color = Color.BLACK) -> Array: return [cat_color]
static func method_exit_cat_args() -> Array: return []
static func method_callable_args(callable: Callable) -> Array: return [callable]
static func method_custom_args(control: Control) -> Array: return [control]





