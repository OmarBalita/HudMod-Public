#############################################################################
##  This file is part of: HudMod Video Editor                              ##
##  https://omar-top.itch.io/hudmod-video-editor                           ##
## ----------------------------------------------------------------------- ##
##  Copyright © 2026 Omar Mohammed Balita.                                 ##
## ----------------------------------------------------------------------- ##
## GPLv3                                                                   ##
#############################################################################
class_name CompPopup extends InOutComponentRes

func _inout(frame: int) -> void:
	submit_stacked_value_with_custom_method(&"scale", t_ratio, MethodType.MULTIPLY)

