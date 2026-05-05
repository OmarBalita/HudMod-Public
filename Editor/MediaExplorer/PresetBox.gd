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
class_name PresetBox extends CreatedBox

var preset_category: Category

func _init(_media_explorer: MediaExplorer) -> void:
	super(_media_explorer)

func _ready_options() -> void:
	super()
	preset_category = add_category(&"Preset", false)

func _init_card(key: String, info: Dictionary, type: String) -> CreatedCard:
	var preset_card:= PresetCard.new(self, 0)
	var preset_clip_res: MediaClipRes = MediaCache.get_preset_media_res(key)
	preset_card.path_or_name = key
	if preset_clip_res:
		preset_card.display_name = preset_clip_res.id
	preset_card.created_card_type = CreatedCard.CreatedCardType.CARD_TYPE_PRESET
	preset_card.preset_clip_res = preset_clip_res
	preset_card.disabled = info.has(&"discard")
	return preset_card

func _get_created_box_category() -> Category:
	return preset_category

func create_presets(preset_media_ress: Array[MediaClipRes], global: bool) -> void:
	var preset_files_pathes: PackedStringArray = EditorServer.create_presets(preset_media_ress, global)
	set_display_file_system(get_true_file_system(global))
	create_files(curr_display_path, preset_files_pathes)
	update()

func delete_selected(delete_real_files: bool = false) -> void:
	var paths_or_names: PackedStringArray = get_selected_paths_or_names()
	for path: String in paths_or_names: MediaServer.store_not_deleted_resource(path)
	delete_files_or_folders(curr_display_path, paths_or_names, delete_real_files)
	update()

func _on_project_server_project_opened(project_res: ProjectRes) -> void:
	super(project_res)
	await get_tree().process_frame
	project_file_system = ProjectServer2.preset_file_system
	global_file_system = GlobalServer.preset_file_system
	display_file_system = project_file_system
	update()


class PresetCard extends CreatedBox.CreatedCard:
	
	static var preset_thumbnail: Texture2D = preload("res://Asset/Icons/preset.png")
	
	@export var preset_clip_res: MediaClipRes
	
	func _ready() -> void:
		display_texture = null if disabled or preset_clip_res == null else preset_thumbnail
		super()
	
	func get_media_ress() -> Array[MediaClipRes]:
		if preset_clip_res == null:
			return []
		var copy_clip_res: MediaClipRes = preset_clip_res.duplicate_media_res()
		copy_clip_res.move_layers_clips_deep(PlaybackServer.position - copy_clip_res.get_meta(&"preset_offset", 0))
		return [copy_clip_res]
	
	func add_media_ress(layer_index: int, frame_in: int, auto_init: bool = true) -> void:
		super(layer_index, frame_in, false)
	
	func _get_context_menu_options() -> Array[Dictionary]:
		return [
			{text = "delete"},
			{text = "Move to"}
		]
	
	func _on_context_menu_id_pressed(id: int) -> void:
		match id:
			0: delete()
			1: popup_move_to_window()

