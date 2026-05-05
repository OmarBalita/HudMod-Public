#############################################################################
##  This file is part of: HudMod Video Editor                              ##
##  https://omar-top.itch.io/hudmod-video-editor                           ##
## ----------------------------------------------------------------------- ##
##  Copyright © 2026 Omar Mohammed Balita.                                 ##
## ----------------------------------------------------------------------- ##
## GPLv3                                                                   ##
#############################################################################
class_name CompBlurRotational extends PassShaderComponentRes

@export var auto: bool = false
@export var center: Vector2 = Vector2.ZERO
@export var blur_amount: float = .05
@export var quality: int = 8
@export var clip_border: bool = false
@export var transparancy: bool = true

func emit_res_changed() -> void:
	super(); if owner: owner.shared_data_clear()

func _get_exported_props() -> Dictionary[StringName, ExportInfo]:
	return {
		&"auto": export(bool_args(auto)),
		&"center": export(vec2_args(center)),
		&"blur_amount": export(float_args(blur_amount, -PI, PI, .001)),
		&"quality": export(int_args(quality, 1, 128)),
		&"clip_border": export(bool_args(clip_border)),
		&"transparancy": export(bool_args(transparancy))
	}

func _postprocess(frame: int) -> void:
	var _blur_amount: float
	
	if auto:
		var dict: Dictionary[StringName, Array] = owner.shared_data_get_custom_stacked_values_at(frame - 1)
		var rot_key: StringName = &"rotation_degrees"
		if dict.has(rot_key):
			var delta: float = owner.get_stacked_values_key_result(rot_key) - owner.get_custom_stacked_values_key_result(dict, rot_key)
			_blur_amount = delta * blur_amount
	else:
		_blur_amount = blur_amount
	
	set_shader_prop(&"center", center)
	set_shader_prop(&"blur_amount", _blur_amount)
	set_shader_prop(&"quality", quality)
	set_shader_prop(&"clip_border", clip_border)
	set_shader_prop(&"transparancy", transparancy)

static func _shader() -> Shader:
	return preload("res://Build/Shader/Image/BlurRotational.gdshader")
