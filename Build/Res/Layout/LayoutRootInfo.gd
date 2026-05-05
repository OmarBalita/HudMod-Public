#############################################################################
##  This file is part of: HudMod Video Editor                              ##
##  https://omar-top.itch.io/hudmod-video-editor                           ##
## ----------------------------------------------------------------------- ##
##  Copyright © 2026 Omar Mohammed Balita.                                 ##
## ----------------------------------------------------------------------- ##
## GPLv3                                                                   ##
#############################################################################
class_name LayoutRootInfo extends LayoutInfo

signal layout_changed()

@export_group(&"LayoutRootInfo")
@export var layout_name: StringName
@export var layout_image: Texture2D

@export var windowed_infos: Array[WindowedInfo]

func get_layout_name() -> StringName:
	return layout_name

func set_layout_name(new_val: StringName) -> void:
	layout_name = new_val

func get_layout_image() -> Texture2D:
	return layout_image

func set_layout_image(new_val: Texture2D) -> void:
	layout_image = new_val

func open(editors: Dictionary[StringName, EditorControl]) -> Dictionary[StringName, Variant]:
	var windows: Array[Window]
	for windowed_info: WindowedInfo in windowed_infos:
		var header_panel: EditorControl.HeaderPanel = editors[windowed_info.editor_name].header_panel
		header_panel.to_window(windowed_info, false, false)
	return super.open(editors).merged({&"windows": windows})

static func parse(split_container: SplitContainer, layout_id: Object = LayoutRootInfo) -> LayoutRootInfo:
	var layout_info: LayoutRootInfo = super.parse(split_container, layout_id)
	layout_info.set_root_deep(layout_info)
	
	for window: Window in WindowManager.editor_windows_folder.get_children():
		layout_info.windowed_infos.append(WindowedInfo.new_windowed_info(
			window.get_meta(&"editor_name"),
			window.current_screen,
			window.position,
			window.size,
			window.mode
		))
	
	return layout_info

