#############################################################################
##	This file is part of: HudMod Video Editor							   ##
##	https://omar-top.itch.io/hudmod-video-editor						   ##
## ----------------------------------------------------------------------- ##
##	Copyright © 2026 Omar Mohammed Balita.								   ##
## ----------------------------------------------------------------------- ##
##	This program is free software: you can redistribute it and/or modify   ##
##	it under the terms of the GNU General Public License as published by   ##
##	the Free Software Foundation, either version 3 of the License, or	   ##
##	(at your option) any later version.									   ##
##																		   ##
##	This program is distributed in the hope that it will be useful,		   ##
##	but WITHOUT ANY WARRANTY; without even the implied warranty of		   ##
##	MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the		   ##
##	GNU General Public License for more details.						   ##
##																		   ##
##	You should have received a copy of the GNU General Public License	   ##
##	along with this program. If not, see <https://www.gnu.org/licenses/>.  ##
#############################################################################
class_name UsableRes extends Resource

signal res_changed()

enum MethodType {
	SET,
	ADD,
	SUB,
	MULTIPLY,
	DIVIDE
}

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

const UNDO_REDO_COMMIT_SET_PROP: StringName = &"set_prop_action_sended"

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

func set_prop_and_emit(property_key: StringName, property_val: Variant) -> void:
	set_prop(property_key, property_val)
	emit_res_changed()

func emit_res_changed() -> void:
	res_changed.emit()


func register_prop(property_key: StringName, property_val: Variant, set_func: StringName = &"_set_prop_default", get_func: StringName = &"_get_prop_default") -> void:
	properties[property_key] = {"v": property_val, "s": set_func, "g": get_func}

func register_props(_properties: Dictionary[StringName, Variant], set_func: StringName = &"_set_prop_default", get_func: StringName = &"_get_prop_default") -> void:
	for property_key: StringName in _properties:
		var property_default_val: Variant = _properties.get(property_key)
		register_prop(property_key, property_default_val, set_func, get_func)

func loop_props(method: Callable) -> void:
	for property_name: StringName in properties:
		var property_val: Variant = get_prop(property_name)
		method.call(property_name, property_val)


func _get_exported_props() -> Dictionary[StringName, Dictionary]:
	return {}

func _custom_editor_spawned(edit_cont: EditContainer, props_editors: Dictionary[StringName, Control]) -> void:
	pass




const TYPES_UNANIMATABLES: Array[int] = [TYPE_ARRAY, TYPE_OBJECT]
const TYPES_HAVE_SCROLL_CONTROLLERS: Array[StringName] = [&"float", &"int", &"Color", &"Vector2", &"Vector3"]

static func create_custom_edit(name: String, usable_res: UsableRes, usable_ress: Array[UsableRes] = [], custom_exported_props: Dictionary[StringName, Dictionary] = {}, search_line_edit: LineEdit = null, is_vertical: bool = true) -> EditContainer:
	
	var usable_res_script: Script = usable_res.get_script()
	
	if not usable_ress.has(usable_res):
		usable_ress.append(usable_res)
	
	var usable_res_classname: StringName = usable_res_script.get_global_name()
	var usable_res_inh: Array[StringName] = ClassServer.classname_get_inh(usable_res_classname)
	
	var exported_props: Dictionary[StringName, Dictionary] = usable_res._get_exported_props() if custom_exported_props.is_empty() else custom_exported_props
	
	var edit_cont: EditContainer = IS.create_edit_cont(name, true, false, false, false)
	var body_panel: PanelContainer = IS.create_panel_container()
	var body_margin: MarginContainer = IS.create_margin_container(8, 8, 8, 8)
	
	var edits_box_container: BoxContainer = IS.create_box_container(8, is_vertical)
	var curr_box_container: BoxContainer = edits_box_container
	var categories_entered: Array[Category]
	
	edits_box_container.alignment = BoxContainer.ALIGNMENT_BEGIN
	
	edit_cont.add_child(body_panel)
	body_panel.add_child(body_margin)
	body_margin.add_child(edits_box_container)
	
	edit_cont.controller = edits_box_container
	#edits_box_container.set_meta(&"owner", edit_cont)
	
	var ui_profile: UIProfile = UIProfile.new()
	var ui_conds_keys: Array
	var ui_conds_vals: Array
	
	var properties_controls: Dictionary[StringName, Control] = {}
	
	edit_cont.tree_entered.connect(EditorServer.usable_ress_editors_register_editor.bind(usable_res, usable_ress, edit_cont, properties_controls, ui_profile))
	
	const UI_COND_RESULT: Array = [true]
	
	var ui_method: Callable = func(input_method: Callable, expected_results: Array, prop_name: String, ctrl: Control) -> bool:
		return (StringHelper.fuzzy_search(search_line_edit.text.to_lower(), prop_name) or ctrl is Category) and expected_results.has(input_method.call())
	
	var ui_method2: Callable = func(prop_name: String, ctrl: Control) -> bool:
		return StringHelper.fuzzy_search(search_line_edit.text.to_lower(), prop_name) or ctrl is Category
	
	for key: StringName in exported_props:
		var ctrlr_info: Dictionary = exported_props[key]
		var ctrlr_args: Array = ctrlr_info.args
		var ui_cond: Array = ctrlr_info.ui_cond
		
		var control: Control
		
		if ctrlr_info.has(&"method_type"):
			
			match ctrlr_info.method_type:
				
				ExportMethodType.METHOD_ENTER_CATEGORY:
					var cat_color: Color = ctrlr_args[0] if ctrlr_args.size() else Color.TRANSPARENT
					var cat: Category = IS.create_category(true, key, cat_color, Vector2.ZERO, false)
					cat.content_color = Color.from_hsv(.6 + categories_entered.size() * .2, .6, .6, .5)
					curr_box_container.add_child(cat)
					categories_entered.append(cat)
					curr_box_container = cat.content_container
					control = cat
				
				ExportMethodType.METHOD_EXIT_CATEGORY:
					categories_entered.resize(categories_entered.size() - 1)
					curr_box_container = categories_entered.back().content_container if categories_entered.size() else edits_box_container
				
				ExportMethodType.METHOD_CALLABLE:
					var callable_button: Button = IS.create_button(key, IS.TEXTURE_MEGAPHONE, "", true)
					
					var button_style: StyleBoxFlat = callable_button.get_theme_stylebox(&"normal").duplicate(false)
					var button_color: Color = ctrlr_args[1]
					button_style.bg_color = button_color
					button_style.border_color = button_color.lightened(.3)
					IS.set_button_style(callable_button, button_style)
					
					if ctrlr_args[2] != null:
						callable_button.icon = ctrlr_args[2]
						callable_button.add_theme_stylebox_override(&"normal", button_style)
					
					callable_button.pressed.connect(ctrlr_args[0].bind(usable_ress))
					curr_box_container.add_child(callable_button)
					properties_controls[key] = callable_button
					control = callable_button
				
				ExportMethodType.METHOD_CUSTOM_EXPORT:
					var custom_control: Control = ctrlr_args[0]
					curr_box_container.add_child(custom_control)
					properties_controls[key] = custom_control
					control = custom_control
		
		else:
			var val: Variant = ctrlr_args[0]
			
			var prop_edit_cont: EditContainer = ClassServer.create_prop_editor(key, val, ctrlr_args, usable_ress, search_line_edit)
			
			if prop_edit_cont:
				var is_type_animatable: bool = typeof(val) not in TYPES_UNANIMATABLES
				var changeable: bool = is_type_animatable and ctrlr_info.keyframable
				var keyframable: bool = changeable and (usable_res_inh.has(&"ComponentRes") or usable_res_inh.has(&"MediaClipRes"))
				
				prop_edit_cont.default_val = ClassServer.classname_get_property_default_value(usable_res.get_classname(), key)
				
				prop_edit_cont.set_curr_value(val)
				prop_edit_cont.keyframable = keyframable
				prop_edit_cont.resetable = changeable
				prop_edit_cont.copypast = changeable
				
				properties_controls[key] = prop_edit_cont
				
				prop_edit_cont.val_changed.connect(
					func(new_value: Variant) -> void:
						_handle_prop_value_changed(key, new_value, usable_res, usable_ress)
						ui_profile.update()
				)
				
				if keyframable:
					prop_edit_cont.keyframe_sended.connect(
						func(new_value: Variant) -> void:
							for _usable_res: UsableRes in usable_ress:
								_usable_res.request_animation_keyframe(_usable_res, key, new_value)
					)
				
				curr_box_container.add_child(prop_edit_cont)
				control = prop_edit_cont
		
		if control:
			
			key = key.replace("_", " ").to_lower()
			IS.expand(control, true, true)
			
			if ui_cond:
				var root_ui_cond: Array
				if search_line_edit:
					root_ui_cond = [ui_method.bind(ui_cond[0], ui_cond[1], key, control), UI_COND_RESULT]
				else:
					root_ui_cond = ui_cond
				ui_conds_keys.append(root_ui_cond)
				ui_conds_vals.append([control])
			
			elif search_line_edit:
				ui_conds_keys.append([ui_method2.bind(key, control), UI_COND_RESULT])
				ui_conds_vals.append([control])
	
	ui_profile.set_ui_conditions(ui_conds_keys, ui_conds_vals)
	ui_profile.update()
	
	if search_line_edit:
		search_line_edit.text_changed.connect(
			func _on_search_line_edit_text_changed(new_text: String) -> void:
				ui_profile.update()
		)
	
	return edit_cont


static func _handle_prop_value_changed(property_key: StringName, new_value: Variant, usable_res: UsableRes, usable_ress: Array[UsableRes] = []) -> void:
	var owner_usable_res_idx: int = usable_ress.find(usable_res)
	var old_values: Array = usable_ress.map(func(element: UsableRes) -> Variant: return element.get_prop(property_key))
	var new_values: Array = []
	new_values.resize(usable_ress.size())
	new_values.fill(new_value)
	
	var method_set_all: Callable = func(target_values: Array) -> void:
		
		for idx: int in usable_ress.size():
			var _usable_res: UsableRes = usable_ress[idx]
			_usable_res.set_prop_and_emit(property_key, target_values[idx])
	
	method_set_all.call(new_values)
	
	if not usable_res.has_meta(UNDO_REDO_COMMIT_SET_PROP):
		if ClassServer.value_get_classname(new_value) in TYPES_HAVE_SCROLL_CONTROLLERS:
			usable_res.set_meta(UNDO_REDO_COMMIT_SET_PROP, true)
		
		ProjectServer2.commit_action(
			"set_{prop_key}".format({"prop_key": property_key}),
			method_set_all.bind(new_values),
			method_set_all.bind(old_values),
			false
		)
		
		await Engine.get_main_loop().create_timer(.4).timeout
		usable_res.remove_meta(UNDO_REDO_COMMIT_SET_PROP)

func get_classname() -> StringName:
	return get_script().get_global_name()


enum ExportMethodType {
	METHOD_ENTER_CATEGORY,
	METHOD_EXIT_CATEGORY,
	METHOD_CALLABLE,
	METHOD_CUSTOM_EXPORT,
}


static func export(args: Array, ui_cond: Array = [], keyframable: bool = true) -> Dictionary[StringName, Variant]:
	return {
		&"args": args,
		&"ui_cond": ui_cond,
		&"keyframable": keyframable
	}

static func export_method(method_type: ExportMethodType, args: Array = [], ui_cond: Array = []) -> Dictionary:
	return {
		&"method_type": method_type,
		&"args": args,
		&"ui_cond": ui_cond
	}

static func bool_args(val: bool) -> Array: return [val]
static func string_args(val: String, controller_type: IS.StringControllerType = 0, filter: Array[String] = [], placeholder: String = "", editable: bool = true) -> Array: return [val, placeholder, controller_type, filter, editable]
static func int_args(val: int, min: float = -INF, max: float = INF, step: int = 1, spin_scale: int = 1, magnet_step: int = 5, controller_type: IS.FloatControllerType = 0) -> Array: return [val, min, max, step, spin_scale, magnet_step, true, controller_type]
static func options_args(val: int, options: Dictionary) -> Array: return [val, -INF, INF, 1, 1, 1, true, IS.FloatControllerType.TYPE_OPTIONS, options]
static func float_args(val: float, min: float = -INF, max: float = INF, step: float = .01, spin_scale: float = .1, magnet_step: float = 5., controller_type: IS.FloatControllerType = 0) -> Array: return [val, min, max, step, spin_scale, magnet_step, false, controller_type]
static func vec2_args(val: Vector2, is_int: bool = false, has_lock_button: bool = false, suffix: FloatController.SuffixType = 0, xminmax: Vector2 = Vector2(-INF, INF), yminmax: Vector2 = Vector2(-INF, INF)) -> Array: return [val, is_int, has_lock_button, suffix, xminmax, yminmax]
static func vec3_args(val: Vector3, suffix: FloatController.SuffixType = 0, xminmax: Vector2 = Vector2(-INF, INF), yminmax: Vector2 = Vector2(-INF, INF), zminmax: Vector2 = Vector2(-INF, INF)) -> Array: return [val, suffix, xminmax, yminmax, zminmax]
static func color_args(val: Color, min_size: Vector2 = IS.EDIT_BOX_MIN_SIZE, name_alignment: int = 0, controller_type: IS.ColorControllerType = 0) -> Array: return [val, min_size, name_alignment, controller_type]
static func list_args(val: Array, list_classname: StringName, can_add_element: bool = true, can_remove_element: bool = true,
	can_duplicate_element: bool = true, can_change_element_priority: bool = true, min_elements_count: int = 0) -> Array:
	return [val, list_classname, can_add_element, can_remove_element, can_duplicate_element, can_change_element_priority, min_elements_count]
static func mediaclipres_args(val: MediaClipRes, cond_func: Callable) -> Array: return [val, cond_func]

static func method_enter_cat_args(cat_color: Color = Color.BLACK) -> Array: return [cat_color]
static func method_exit_cat_args() -> Array: return []
static func method_callable_args(callable: Callable, color: Color = IS.color_accent, icon: Texture2D = IS.TEXTURE_MEGAPHONE) -> Array: return [callable, color, icon]
static func method_custom_args(control: Control) -> Array: return [control]
