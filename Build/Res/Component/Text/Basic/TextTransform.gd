#############################################################################
##  This file is part of: HudMod Video Editor                              ##
##  https://omar-top.itch.io/hudmod-video-editor                           ##
## ----------------------------------------------------------------------- ##
##  Copyright © 2026 Omar Mohammed Balita.                                 ##
## ----------------------------------------------------------------------- ##
## GPLv3                                                                   ##
#############################################################################
class_name CompTextTransform extends ComponentRes

@export var xx: float = 1.
@export var xy: float
@export var yx: float
@export var yy: float = 1.
@export var xo: float
@export var yo: float

func _get_exported_props() -> Dictionary[StringName, ExportInfo]:
	return {
		&"xx": export(float_args(xx)),
		&"xy": export(float_args(xy)),
		&"yx": export(float_args(yx)),
		&"yy": export(float_args(yy)),
		&"xo": export(float_args(xo)),
		&"yo": export(float_args(yo))
	}

func _process(frame: int) -> void:
	update_transform()

func _delete() -> void:
	owner.font.update_transform()
	owner.dirty_level = 2

func update_transform() -> void:
	var font: FontVariation = owner.font.get_font()
	
	var old_transform: Transform2D = font.variation_transform
	var transform: Transform2D = Transform2D(Vector2(xx, xy), Vector2(yx, yy), Vector2(xo, yo))
	
	if old_transform != transform:
		font.variation_transform = transform
		owner.dirty_level = 2

