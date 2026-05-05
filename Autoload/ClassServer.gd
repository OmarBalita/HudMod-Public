#############################################################################
##  This file is part of: HudMod Video Editor                              ##
##  https://omar-top.itch.io/hudmod-video-editor                           ##
## ----------------------------------------------------------------------- ##
##  Copyright © 2026 Omar Mohammed Balita.                                 ##
## ----------------------------------------------------------------------- ##
##  This program is free software: you can redistribute it and/or modify   ##
##  it under the terms of the GNU General Public License as published by   ##
##  the Free Software Foundation, either version 3 of the License, or      ##
##  (at your option) any later version.                                    ##
##                                                                         ##
##  This program is distributed in the hope that it will be useful,        ##
##  but WITHOUT ANY WARRANTY; without even the implied warranty of         ##
##  MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the           ##
##  GNU General Public License for more details.                           ##
##                                                                         ##
##  You should have received a copy of the GNU General Public License      ##
##  along with this program. If not, see <https://www.gnu.org/licenses/>.  ##
#############################################################################
extends Node

const CLASSNAME_BUILTIN_REVERSE_MAP: Dictionary[StringName, Variant.Type] = {
	&"Nil": TYPE_NIL,
	&"bool": TYPE_BOOL,
	&"String": TYPE_STRING,
	&"int": TYPE_INT,
	&"float": TYPE_FLOAT,
	&"Vector2": TYPE_VECTOR2,
	&"Vector3": TYPE_VECTOR3,
	&"Color": TYPE_COLOR,
	&"Array": TYPE_ARRAY,
	&"Object": TYPE_OBJECT
}
const CLASSNAME_USABLE_RES: StringName = &"UsableRes"
const CLASSNAME_COMPONENT_RES: StringName = &"ComponentRes"
const CLASSNAME_MEDIA_CLIP_RES: StringName = &"MediaClipRes"

var comps_sections_infos: Dictionary[StringName, CompsSectionInfo] = {
	&"Display2D": CompsSectionInfo.new(null, "", [&"Basic", &"Transformation", &"InOutAnimation"]),
	&"Image": CompsSectionInfo.new(null, "", [&"Basic", &"Enhance", &"Cinematic", &"Retro", &"Artistic", &"Blur", &"Distortion", &"PostProcessing"]),
	&"Color": CompsSectionInfo.new(null, "", [&"ColorCorrection", &"ColorGrading"]),
	&"Transition": CompsSectionInfo.new(null, "", [&"Basic"]),
	&"Sound": CompsSectionInfo.new(null, "", [&"Basic"]),
	&"Layout": CompsSectionInfo.new(null, "", [&"Layout"]),
	&"Text": CompsSectionInfo.new(null, "", [&"Basic", &"Shape", &"Color", &"Animation", &"InOutAnimation", &"Generate"]),
	#&"Draw": CompsSectionInfo.new(null, "", []),
	&"Particles": CompsSectionInfo.new(null, "", [&"Display", &"Physics"]),
	&"Camera": CompsSectionInfo.new(null, "", [&"Basic", &"PostProcessing"])
}

@onready var base_classes: Dictionary[Variant.Type, BaseClassInfo] = {
	TYPE_NIL: BaseClassInfo.new(preload("uid://cmmfo46f2kkr7"), ""),
	TYPE_BOOL: BaseClassInfo.new(preload("uid://dwy7607puvtdi"), "", IS.create_bool_edit),
	TYPE_STRING: BaseClassInfo.new(preload("uid://bg11m2mx7vpor"), "", IS.create_string_edit),
	TYPE_INT: BaseClassInfo.new(preload("uid://bcgchdgeqi5u4"), "", IS.create_float_edit),
	TYPE_FLOAT: BaseClassInfo.new(preload("uid://b7ihkyp0ki0gk"), "", IS.create_float_edit),
	TYPE_VECTOR2: BaseClassInfo.new(preload("uid://b44njuxwqotlf"), "", IS.create_vec2_edit),
	TYPE_VECTOR3: BaseClassInfo.new(preload("uid://hyfoqvtp8u4t"), "", IS.create_vec3_edit),
	TYPE_COLOR: BaseClassInfo.new(preload("uid://b2nqjyp4cghvq"), "", IS.create_color_edit),
	TYPE_ARRAY: BaseClassInfo.new(preload("uid://dnimcsg6d8dfy"), "", IS.create_list_edit),
	TYPE_OBJECT: ObjectClassInfo.new()
}
var object_classes: Dictionary[StringName, Dictionary] # All Object base
var usable_res_classes: Dictionary[StringName, Dictionary] # All UsableRes base
var component_res_classes: Dictionary[StringName, Dictionary] # Just ComponentRes base
var media_clip_classes: Dictionary[StringName, Dictionary] # Just MediaClipRes base
var component_res_sorted_by_sections: Dictionary[StringName, Dictionary] = {}

func _ready() -> void:
	_build_classes()

func _build_classes() -> void:
	const COMPS_BASE_DIR: String = "res://Build/Res/Component"
	var comps_base_dir_length: int = COMPS_BASE_DIR.length()
	
	var global_class_list: Array[Dictionary] = ProjectSettings.get_global_class_list()
	
	for section_key: StringName in comps_sections_infos:
		var comp_section_info: CompsSectionInfo = comps_sections_infos[section_key]
		var subsections: Dictionary[StringName, Dictionary] = {}
		component_res_sorted_by_sections[section_key] = subsections
		for subsection: StringName in comp_section_info.subsections:
			subsections[subsection] = {} as Dictionary[StringName, Dictionary]
	
	for class_builtin_info: Dictionary in global_class_list:
		var classname: StringName = class_builtin_info.class
		var script: Script = load(class_builtin_info.path)
		
		var inheritance_classnames: Array[StringName]
		var basescript: Script = script
		while basescript != null:
			inheritance_classnames.append(basescript.get_global_name())
			basescript = basescript.get_base_script()
		
		var class_custom_info: Dictionary[StringName, Variant] = {
			&"icon": load(class_builtin_info.icon) if FileAccess.file_exists(class_builtin_info.icon) else null,
			&"script": script,
			&"inh": inheritance_classnames
		}
		object_classes[classname] = class_custom_info
		
		if inheritance_classnames.has(CLASSNAME_USABLE_RES):
			var ref_res: UsableRes = script.new()
			class_custom_info[&"reference_resource"] = ref_res
			usable_res_classes[classname] = class_custom_info
		
		if inheritance_classnames.has(CLASSNAME_COMPONENT_RES):
			
			var base_dir: String = class_builtin_info.path.get_base_dir()
			
			if base_dir.begins_with(COMPS_BASE_DIR):
				
				var base_dir_arr: PackedStringArray = base_dir.split("/")
				var comp_section_key: String = base_dir_arr[-2]
				
				if component_res_sorted_by_sections.has(comp_section_key):
					var comp_subsection_key: String = base_dir_arr[-1]
					component_res_sorted_by_sections[comp_section_key][comp_subsection_key][classname] = class_custom_info
			
			component_res_classes[classname] = class_custom_info
		
		if inheritance_classnames.has(CLASSNAME_MEDIA_CLIP_RES):
			media_clip_classes[classname] = class_custom_info

func get_base_classes() -> Dictionary[Variant.Type, BaseClassInfo]: return base_classes
func get_object_classes() -> Dictionary[StringName, Dictionary]: return object_classes
func get_usable_res_classes() -> Dictionary[StringName, Dictionary]: return usable_res_classes
func get_component_res_classes() -> Dictionary[StringName, Dictionary]: return component_res_classes
func get_media_clip_classes() -> Dictionary[StringName, Dictionary]: return media_clip_classes

func builtin_classname_to_type(classname: StringName) -> Variant.Type:
	return CLASSNAME_BUILTIN_REVERSE_MAP[classname] if CLASSNAME_BUILTIN_REVERSE_MAP.has(classname) else TYPE_OBJECT

func classname_get_icon(classname: StringName) -> Texture2D:
	var type: Variant.Type = builtin_classname_to_type(classname)
	if type == TYPE_OBJECT:
		var class_info: Dictionary[StringName, Variant] = object_classes[classname]
		if class_info.icon == null: return ObjectClassInfo.default_icon
		else: return class_info.object
	else: return base_classes[type].icon

func classname_get_script(classname: StringName) -> Script:
	return object_classes[classname].script if object_classes.has(classname) else null

func classname_get_inh(classname: StringName) -> Array[StringName]:
	return object_classes[classname].inh if object_classes.has(classname) else [] as Array[StringName]

## classname should be a UsableRes
func classname_get_property_default_value(classname: StringName, key: StringName) -> Variant:
	return usable_res_classes[classname].reference_resource.get_prop(key) if usable_res_classes.has(classname) else null

func classname_new(classname: StringName) -> Variant:
	var type: Variant.Type = builtin_classname_to_type(classname)
	if type == TYPE_OBJECT:
		return object_classes[classname].script.new()
	else:
		match type:
			TYPE_BOOL: return bool()
			TYPE_STRING: return String()
			TYPE_INT: return int()
			TYPE_FLOAT: return float()
			TYPE_VECTOR2: return Vector2()
			TYPE_VECTOR3: return Vector3()
			TYPE_COLOR: return Color()
			TYPE_ARRAY: return Array()
			_: return null

func value_get_classname(value: Variant) -> StringName:
	var value_type: Variant.Type = typeof(value)
	if value_type == TYPE_OBJECT:
		var script: Script = value.get_script()
		if script: return script.get_global_name()
		else: return StringName(value.get_class())
	else: return type_string(value_type)

func comps_get_section_comps(section: StringName) -> Dictionary[StringName, Dictionary]:
	return component_res_sorted_by_sections[section]

func create_prop_editor(prop_name: StringName, prop_val: Variant, controller_args: Array = [], usable_ress: Array[UsableRes] = [], search_line_edit: LineEdit = null) -> EditContainer:
	var result: Array[Control]
	var prop_type: Variant.Type = typeof(prop_val)
	if prop_type == TYPE_OBJECT:
		prop_val = prop_val as Object
		if prop_val is UsableRes:
			var nested_usable_ress: Array[UsableRes]
			for usable_res: UsableRes in usable_ress:
				nested_usable_ress.append(usable_res.get_prop(prop_name))
			return prop_val.create_custom_edit(prop_name, prop_val, nested_usable_ress, search_line_edit)
		return null
	
	else:
		return base_classes[prop_type].editor_method.callv([prop_name] + controller_args)


class AnythingInfo extends Resource:
	@export var icon: Texture2D
	@export var description: String
	
	func _init(_icon: Texture2D = null, _description: String = "") -> void:
		icon = _icon
		description = _description
	
	func get_icon() -> Texture2D: return icon
	func set_icon(new_val: Texture2D) -> void: icon = new_val
	
	func get_description() -> String: return description
	func set_description(new_val: String) -> void: description = new_val

class CompsSectionInfo extends AnythingInfo:
	@export var subsections: Array[StringName]
	
	func _init(_icon: Texture2D = null, _description: String = "", _subsections: Array[StringName] = []) -> void:
		super(_icon, _description)
		subsections = _subsections

class BaseClassInfo extends AnythingInfo:
	@export var editor_method: Callable
	
	func _init(_icon: Texture2D = null, _description: String = "", _editor_method: Callable = Callable()) -> void:
		super(_icon, _description)
		editor_method = _editor_method

class ObjectClassInfo extends BaseClassInfo:
	static var default_icon: Texture2D = preload("uid://bxr7lodry7wjb")
	@export var object_classes: Dictionary[StringName, Dictionary]
	
	static func get_default_icon() -> Texture2D: return default_icon
	static func set_default_icon(new_val: Texture2D) -> void: default_icon = new_val

