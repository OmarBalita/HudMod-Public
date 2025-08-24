extends Node

const TYPES_MAP: Array[int] = [TYPE_NIL, TYPE_BOOL, TYPE_STRING, TYPE_INT, TYPE_FLOAT, TYPE_VECTOR2, TYPE_VECTOR3, TYPE_COLOR, TYPE_ARRAY]

const RES_ICON: Texture2D = preload("uid://bxr7lodry7wjb")


@onready var basic_types: Array[Dictionary] = [
	{text = "None", icon = preload("uid://cmmfo46f2kkr7"), dflt = null, ctrlr = null, dflt_ctrlr_args = {}},
	{text = "Bool", icon = preload("uid://dwy7607puvtdi"), dflt = false, ctrlr = InterfaceServer.create_bool_edit, dflt_ctrlr_args = CtrlrHelper.get_bool_controller_args([])},
	{text = "String", icon = preload("uid://bg11m2mx7vpor"), dflt = "", ctrlr = InterfaceServer.create_line_edit_edit, dflt_ctrlr_args = CtrlrHelper.get_string_controller_args([])},
	{text = "Int", icon = preload("uid://bcgchdgeqi5u4"), dflt = 0, ctrlr = InterfaceServer.create_float_edit, dflt_ctrlr_args = CtrlrHelper.get_float_controller_args([], true, 0, -INF, INF, 1.0, 1.0, 10.0)},
	{text = "Float", icon = preload("uid://b7ihkyp0ki0gk"), dflt = .0, ctrlr = InterfaceServer.create_float_edit, dflt_ctrlr_args = CtrlrHelper.get_float_controller_args([])},
	{text = "Vec2", icon = preload("uid://b44njuxwqotlf"), dflt = Vector2.ZERO, ctrlr = null, dflt_ctrlr_args = {}},
	{text = "Vec3", icon = preload("uid://hyfoqvtp8u4t"), dflt = Vector3.ZERO, ctrlr = null, dflt_ctrlr_args = {}},
	{text = "Color", icon = preload("uid://b2nqjyp4cghvq"), dflt = Color.BLACK, ctrlr = InterfaceServer.create_color_edit, dflt_ctrlr_args = CtrlrHelper.get_color_controller_args([])},
	{text = "List", icon = preload("uid://dnimcsg6d8dfy"), dflt = [], ctrlr = InterfaceServer.create_list_edit, dflt_ctrlr_args = CtrlrHelper.get_list_controller_args([])},
]

@onready var classes: Array[Dictionary] = [
	{text = "ColorRangeRes", icon = RES_ICON, type_id = ColorRangeRes, ctrlr = InterfaceServer.create_color_range_edit},
	{text = "ColorPaletteRes", icon = RES_ICON, type_id = ColorPaletteRes},
	{text = "GDDrawingRes", icon = RES_ICON, type_id = GDDrawingRes},
	{text = "DrawnEntityRes", icon = RES_ICON, type_id = DrawnEntityRes},
	{text = "CompressedTextureRes", icon = RES_ICON, type_id = CompressedTextureRes},
	#{text = "TimeMarkerRes", type_id = TimeMarkerRes, dflt_ctrlr_args = [], ctrlr = null},
	#{text = "Curve2D", type_id = Curve2D, dflt_ctrlr_args = [], ctrlr = null},
] # All Classes inherited from UsableRes


@onready var types: Array[Dictionary] = basic_types + classes




func get_basic_types() -> Array[Dictionary]:
	return basic_types

func get_classes() -> Array[Dictionary]:
	return classes

func get_types(types_filter: Array[String] = []) -> Array[Dictionary]:
	if types_filter:
		var filtered_types: Array[Dictionary]
		for type_info: Dictionary in types:
			var name = type_info.text
			if not types_filter.has(name):
				continue
			filtered_types.append(type_info)
		return filtered_types
	else:
		return types

func get_type_info(index: int) -> Dictionary:
	return get_types()[index]

func get_type_name(index: int) -> String:
	return get_type_info(index).text

func get_type_icon(index: int) -> Texture2D:
	return get_type_info(index).icon

func get_type_default_val(index: int) -> Variant:
	var result: Variant
	var type_info = get_type_info(index)
	
	if type_info.has("dflt"):
		var main_default_val = type_info.dflt
		if main_default_val is Array:
			result = []
		else:
			result = main_default_val
	elif type_info.has("type_id"):
		result = type_info.type_id.new()
	
	return result

func get_type_controllers_from_val(name: String, val: Variant, args: Variant = null) -> Array[Control]:
	
	var type_info = get_type_info(get_type_from_value(val))
	var type_controllers: Array[Control]
	
	if args == null and type_info.has("dflt_ctrlr_args"):
		args = type_info.dflt_ctrlr_args
	
	if args: args.val = val
	else: args = {'val': val}
	
	args.erase('ui_cond')
	
	if type_info.has("ctrlr"): # Get Instance from Type Editor
		if type_info.ctrlr != null:
			var abs_args = [name] + args.values() # get Editor Arguments ([Name] + Controller Args)
			if args.has("options_info"): # Create Option Controller for Integer Specific State
				type_controllers = InterfaceServer.create_option_edit.callv(abs_args)
			else: # Instance Default Type Controller
				type_controllers = type_info.ctrlr.callv(abs_args)
	else: # Create Custom Resource Editor
		type_controllers = UsableRes.create_custom_edit(name, val)
	
	return type_controllers


func get_type_from_value(value: Variant) -> int:
	var result: int
	var gd_type = typeof(value)
	var type_founded = TYPES_MAP.find(gd_type)
	if type_founded == -1:
		result = get_type_from_name(value.get_res_id())
	else:
		result = type_founded
	return result


func get_type_from_name(name: String, custom_types: Array[Dictionary] = []) -> int:
	var _types = types if custom_types.is_empty() else custom_types
	return _types.find_custom(
		func(element: Dictionary) -> bool:
			return name == element.text
	)


func get_name_from_val(value: Variant) -> String:
	return get_type_name(get_type_from_value(value))







