#############################################################################
##  This file is part of: HudMod Video Editor                              ##
##  https://omar-top.itch.io/hudmod-video-editor                           ##
## ----------------------------------------------------------------------- ##
##  Copyright © 2026 Omar Mohammed Balita.                                 ##
## ----------------------------------------------------------------------- ##
## GPLv3                                                                   ##
#############################################################################
class_name CompOffset extends ComponentRes

@export var offset: Vector2 = Vector2.ZERO
@export var flip_h: bool = false
@export var flip_v: bool = false

func _get_exported_props() -> Dictionary[StringName, ExportInfo]:
	return {
		&"offset": export(vec2_args(offset)),
		&"flip_h": export(bool_args(flip_h)),
		&"flip_v": export(bool_args(flip_v))
	}

func _process(frame: int) -> void:
	submit_stacked_value(&"offset", offset)
	submit_stacked_value_with_custom_method(&"flip_h", flip_h)
	submit_stacked_value_with_custom_method(&"flip_v", flip_v)
