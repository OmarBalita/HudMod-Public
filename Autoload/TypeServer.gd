extends Node

const TYPES_MAP: Array[int] = [TYPE_NIL, TYPE_BOOL, TYPE_STRING, TYPE_INT, TYPE_FLOAT, TYPE_VECTOR2, TYPE_VECTOR3, TYPE_COLOR, TYPE_ARRAY]

#enum {
	#TYPE_NONE,
	#TYPE_BOOL,
	#TYPE_STRING,
	#TYPE_INT,
	#TYPE_FLOAT,
	#TYPE_VEC2,
	#TYPE_VEC3,
	#TYPE_COLOR,
	#TYPE_LIST,
	#TYPE_COLOR_RANGE_RES,
	#TYPE_GDDRAWING_RES,
	#TYPE_DRAWN_ENTITY_RES,
	#TYPE_COMPRESSED_TEXTURE_RES,
	#TYPE_EMPTY_OBJECT,
	#TYPE_DRAW,
	#TYPE_CAMERA_2D
#}

const RES_ICON: Texture2D = preload("uid://bxr7lodry7wjb")

@onready var basic_types: Array[Dictionary] = [
	{text = "None", icon = preload("uid://cmmfo46f2kkr7"), dflt = null, ctrlr = null, dflt_ctrlr_args = {}},
	{text = "Bool", icon = preload("uid://dwy7607puvtdi"), dflt = false, ctrlr = IS.create_bool_edit, dflt_ctrlr_args = CtrlrHelper.get_bool_controller_args([])},
	{text = "String", icon = preload("uid://bg11m2mx7vpor"), dflt = "", ctrlr = IS.create_line_edit_edit, dflt_ctrlr_args = CtrlrHelper.get_string_controller_args([])},
	{text = "Int", icon = preload("uid://bcgchdgeqi5u4"), dflt = 0, ctrlr = IS.create_float_edit, dflt_ctrlr_args = CtrlrHelper.get_float_controller_args([], true, 0, -INF, INF, 1.0, 1.0, 10.0)},
	{text = "Float", icon = preload("uid://b7ihkyp0ki0gk"), dflt = .0, ctrlr = IS.create_float_edit, dflt_ctrlr_args = CtrlrHelper.get_float_controller_args([])},
	{text = "Vec2", icon = preload("uid://b44njuxwqotlf"), dflt = Vector2.ZERO, ctrlr = IS.create_vec2_edit, dflt_ctrlr_args = CtrlrHelper.get_vec2_controller_args([], Vector2.ZERO)},
	{text = "Vec3", icon = preload("uid://hyfoqvtp8u4t"), dflt = Vector3.ZERO, ctrlr = null, dflt_ctrlr_args = {}},
	{text = "Color", icon = preload("uid://b2nqjyp4cghvq"), dflt = Color.BLACK, ctrlr = IS.create_color_edit, dflt_ctrlr_args = CtrlrHelper.get_color_controller_args([])},
	{text = "List", icon = preload("uid://dnimcsg6d8dfy"), dflt = [], ctrlr = IS.create_list_edit, dflt_ctrlr_args = CtrlrHelper.get_list_controller_args([])},
]

@onready var resources: Array[Dictionary] = [
	{text = "ColorRangeRes", icon = RES_ICON, type_id = ColorRangeRes, ctrlr = IS.create_color_range_edit},
	{text = "ColorPaletteRes", icon = RES_ICON, type_id = ColorPaletteRes},
	{text = "GDDrawingRes", icon = RES_ICON, type_id = GDDrawingRes},
	{text = "DrawnEntityRes", icon = RES_ICON, type_id = DrawnEntityRes},
	{text = "CompressedTextureRes", icon = RES_ICON, type_id = CompressedTextureRes},
	#{text = "TimeMarkerRes", type_id = TimeMarkerRes, dflt_ctrlr_args = [], ctrlr = null},
	#{text = "Curve2D", type_id = Curve2D, dflt_ctrlr_args = [], ctrlr = null},
] # All resources inherited from UsableRes

@onready var objects: Dictionary[int, Dictionary] = {
	3: {text = "EmptyObject2D", icon = RES_ICON, type_id = EmptyObject2DRes, object_id = Node2D, category = "Object2D"},
	#4: {text = "Text", icon = RES_ICON, thumbnail = RES_ICON, type_id = TextRes, object_id = Text, category = "Object2D"},
	5: {text = "Draw", icon = RES_ICON, type_id = DrawRes, object_id = GDDraw, category = "Object2D"},
	#6: {text = "Particles", icon = RES_ICON, thumbnail = RES_ICON, type_id = ParticlesRes, object_id = Particles, category = "Object2D"},
	7: {text = "Camera2D", icon = RES_ICON, type_id = Camera2DRes, object_id = Camera2D, category = "Object2D"},
	8: {text = "Audio2D", icon = RES_ICON, type_id = Audio2DRes, object_id = AudioStreamPlayer2D, category = "Object2D"},
}

@onready var sections_hint: Dictionary[String, Dictionary] = {
	"Display2D": {info = {text = "Display 2D", icon = null}, folder_path = "res://Build/Res/UsableRes/Components/Display2D"},
	"Image": {info = {text = "Image", icon = null}, folder_path = "res://Build/Res/UsableRes/Components/Image"},
	"Color": {info = {text = "Color", icon = null}, folder_path = "res://Build/Res/UsableRes/Components/Color"},
	"Transition": {info = {text = "Transition", icon = null}, folder_path = "res://Build/Res/UsableRes/Components/Transition"},
	"Sound": {info = {text = "Sound", icon = null}, folder_path = "res://Build/Res/UsableRes/Components/Sound"},
	"Text": {info = {text = "Text", icon = null}, folder_path = "res://Build/Res/UsableRes/Components/Text"},
	"Draw": {info = {text = "Draw", icon = null}, folder_path = "res://Build/Res/UsableRes/Components/Draw"},
	"Particles": {info = {text = "Particles", icon = null}, folder_path = "res://Build/Res/UsableRes/Components/Particles"},
	"Camera": {info = {text = "Camera", icon = null}, folder_path = "res://Build/Res/UsableRes/Components/Camera"}
} # Key: Section Key, Val: Components Folder Path

@onready var components: Dictionary[String, Array]

@onready var types: Array[Dictionary]



func _ready() -> void:
	update_components()
	update_types()

func update_components() -> void:
	
	for section_key: String in sections_hint:
		
		var section: Array = components.get_or_add(section_key, [])
		var section_folder_path: String = sections_hint[section_key].folder_path
		var components_files: PackedStringArray = DirAccess.get_files_at(section_folder_path)
		
		for file: String in components_files:
			
			if file.get_extension() == "gd":
				var component_name: String = file.get_file().split(".")[0]
				var component_file_path: String = section_folder_path + "/" + file
				var component_script: Script = load(component_file_path)
				var component_info: Dictionary = {text = component_name, icon = null, script = component_script}
				section.append(component_info)

func update_types() -> void:
	types = basic_types + resources
	types.append_array(components.values())


func get_basic_types() -> Array[Dictionary]:
	return basic_types

func get_resources() -> Array[Dictionary]:
	return resources

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
				type_controllers = IS.create_option_edit.callv(abs_args)
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


func get_section_info(section_key: String) -> Dictionary:
	return sections_hint.get(section_key).info

func get_sections_info(sections_keys: Array) -> Array[Dictionary]:
	var result: Array[Dictionary]
	for section_key: String in sections_keys:
		result.append(get_section_info(section_key))
	return result







