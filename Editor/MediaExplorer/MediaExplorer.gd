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
class_name MediaExplorer extends EditorControl

@export_group("Theme")
@export_subgroup("Texture", "texture")
@export var texture_import: Texture2D = preload("res://Asset/Icons/gallery.png")
@export var texture_object: Texture2D = preload("res://Asset/Icons/object.png")
@export var texture_transition: Texture2D = preload("res://Asset/Icons/transition.png")
@export var texture_preset: Texture2D = preload("res://Asset/Icons/flash.png")
@export var texture__filter: Texture2D = preload("res://Asset/Icons/filter.png")
@export var texture_sort: Texture2D = preload("res://Asset/Icons/arrange.png")
@export var texture_search: Texture2D = preload("res://Asset/Icons/magnifying-glass.png")
@export var texture_file: Texture2D = preload("res://Asset/Icons/add-post.png")
@export var texture_folder: Texture2D = preload("res://Asset/Icons/open-file.png")
@export var texture_undo_path: Texture2D = preload("res://Asset/Icons/up-arrow.png")
@export var texture_reload: Texture = preload("res://Asset/Icons/reload.png")
@export_subgroup("Constant")
@export var card_display_size: Vector2 = Vector2(140., 140.)

var curr_media_box: int:
	set(val):
		curr_media_box = val
		for index: int in body.get_child_count():
			var control = body.get_child(index)
			if index != curr_media_box:
				control.hide()
				continue
			control.show()

static var focused_cards: Array[MediaBox.MediaCard]

# RealTime Nodes
var header_menu: Menu
var import_box:= ImportBox.new(self)
var object_box:= ObjectBox.new(self)
var transition_box:= TransitionBox.new(self)
var preset_box:= PresetBox.new(self)



func _ready_editor() -> void:
	header_menu = IS.create_menu([
		MenuOption.new("Import", texture_import),
		MenuOption.new("Object", texture_object),
		MenuOption.new("Transition", texture_transition),
		MenuOption.new("Preset", texture_preset)
	])
	header_menu.focus_index_changed.connect(set_curr_media_box)
	header.add_child(header_menu)
	
	IS.add_children(body, [
		import_box,
		object_box,
		transition_box,
		preset_box
	])

func set_curr_media_box(new_media_box: int) -> void:
	curr_media_box = new_media_box

func import_media(file_path: String, update: bool = true) -> void:
	import_box.create_file(import_box.curr_display_path, file_path)
	if update: update()

func delete_file_or_folder(path_or_name: String, update: bool = true) -> void:
	import_box.delete_file_or_folder(import_box.curr_display_path, path_or_name)
	if update:
		MediaCache.video_contexts_update_max_cache_size()
		update()

func update() -> void:
	import_box.update()


