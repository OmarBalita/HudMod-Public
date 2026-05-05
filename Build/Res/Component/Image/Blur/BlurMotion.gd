#############################################################################
##  This file is part of: HudMod Video Editor                              ##
##  https://omar-top.itch.io/hudmod-video-editor                           ##
## ----------------------------------------------------------------------- ##
##  Copyright © 2026 Omar Mohammed Balita.                                 ##
## ----------------------------------------------------------------------- ##
## GPLv3                                                                   ##
#############################################################################
class_name CompBlurMotion extends PassShaderComponentRes

@export var auto: bool = false
@export var dir: Vector2 = Vector2.RIGHT
@export var blur_amount: float = .05
@export var quality: int = 8
@export var clip_border: bool = false
@export var transparancy: bool = true

func emit_res_changed() -> void:
	super(); if owner: owner.shared_data_clear()

func _get_exported_props() -> Dictionary[StringName, ExportInfo]:
	return {
		&"auto": export(bool_args(auto)),
		&"dir": export(vec2_args(dir), [get.bind(&"auto"), [false]]),
		&"blur_amount": export(float_args(blur_amount, .0, 100., .001)),
		&"quality": export(int_args(quality, 1, 64)),
		&"clip_border": export(bool_args(clip_border)),
		&"transparancy": export(bool_args(transparancy))
	}

func _postprocess(frame: int) -> void:
	var _dir: Vector2
	var _blur_amount: float
	
	if auto:
		var dict: Dictionary[StringName, Array] = owner.shared_data_get_custom_stacked_values_at(frame - 1)
		const POS_KEY: StringName = &"position"
		if dict.has(POS_KEY):
			var old_pos: Vector2 = owner.get_custom_stacked_values_key_result(dict, POS_KEY)
			var delta: Vector2 = owner.get_stacked_values_key_result(POS_KEY) - old_pos
			_dir = delta.normalized()
			_blur_amount = delta.length() * blur_amount
			if _dir == Vector2.ZERO:
				_dir = Vector2.RIGHT
	else:
		_dir = dir
		_blur_amount = blur_amount
	
	set_shader_prop(&"dir", _dir)
	set_shader_prop(&"blur_amount", _blur_amount)
	set_shader_prop(&"quality", quality)
	set_shader_prop(&"clip_border", clip_border)
	set_shader_prop(&"transparancy", transparancy)

static func _shader() -> Shader:
	return preload("res://Build/Shader/Image/BlurMotion.gdshader")

