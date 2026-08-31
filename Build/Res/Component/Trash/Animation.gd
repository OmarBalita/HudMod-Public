#############################################################################
##  This file is part of: HudMod Video Editor                              ##
##  https://omar-top.itch.io/hudmod-video-editor                           ##
## ----------------------------------------------------------------------- ##
##  Copyright © 2026 Omar Mohammed Balita.                                 ##
## ----------------------------------------------------------------------- ##
## GPLv3                                                                   ##
#############################################################################
class_name CompAnimation extends ComponentRes

@export var hframes: int = 1:
	set(val):
		hframes = val
		image_frame = image_frame
@export var vframes: int = 1:
	set(val):
		vframes = val
		image_frame = image_frame
@export var image_frame: int:
	set(val):
		image_frame = clamp(val, 0, hframes * vframes - 1)
		
		if EditorServer.usable_ress_editors_has_editor_with_idx(self, 0):
			var image_frame_edit: EditContainer = EditorServer.usable_ress_editors_get_prop_edit_cont(self, 0, &"image_frame")
			image_frame_edit.set_curr_value(image_frame)

func _get_exported_props() -> Dictionary[StringName, Dictionary]:
	return {
		&"hframes": export(int_args(hframes, 1, INF)),
		&"vframes": export(int_args(vframes, 1, INF)),
		&"image_frame": export(int_args(image_frame, 0, INF)),
	}

func _process(frame: int) -> void:
	submit_stacked_value(&"hframes", hframes)
	submit_stacked_value(&"vframes", vframes)
	submit_stacked_value(&"frame", image_frame)
