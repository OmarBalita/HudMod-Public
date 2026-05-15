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

signal editor_server_ready()

enum MessageMode {
	MESSAGE_MODE_IDLE,
	MESSAGE_MODE_WARNING,
	MESSAGE_MODE_ERROR
}

const ERR_STRENGTH_COLORS: PackedColorArray = [
	Color.WEB_GRAY,
	Color.PALE_GOLDENROD,
	Color.INDIAN_RED
]

const SUPPORTERS_INFO: Dictionary[StringName, Dictionary] = {
	&"Bronze member": {priority = 5, color = Color("de9640ff")},
	&"Silver member": {priority = 4, color = Color("dcdcdc")},
	&"Gold member": {priority = 3, color = Color("dfad2dff")},
	&"Platinum member": {priority = 2, color = Color("252424ff")},
	&"Titanium member": {priority = 1, color = Color("b55bc4ff")},
	&"Diamond member": {priority = 0, color = Color("44bfe4")}
}


static var version_info: VersionInfo = preload("res://Resources/VersionInfo.tres")

static var supporters_url: String = "https://hud-mod-api.vercel.app/api/supporters"

static var app_data_dir: String = OS.get_data_dir() + "/HudMod Video Editor/%s/" % version_info.version_name

static var editor_path: String = app_data_dir + "editor/"
static var editor_layout_path: String = editor_path + "layout/"
static var editor_settings_path: String = editor_path + "editor_settings.res"
static var editor_state_path: String = editor_path + "editor_state.res"

var is_editor_server_ready: bool
var is_supporters_dict_loaded: bool


var editor_settings: AppEditorSettings = ResLoadHelper.load_or_save(editor_settings_path, AppEditorSettings)
var editor_state: EditorStateRes = ResLoadHelper.load_or_save(editor_state_path, EditorStateRes)


var copied_value: Variant
var message_history: Array[Dictionary] # {text = String(), mode = MessageMode.val}
var supporters: Array[Dictionary]

var popup_menu_recent: PopupMenu = IS.create_popup_menu([])
var popup_menu_layout: PopupMenu = IS.create_popup_menu([])
var popup_menu_docks: PopupMenu = IS.create_popup_menu([])

var main: Control
var player: Player
var time_line2: TimeLine2
var media_explorer: MediaExplorer
var properties: Properties2
var color_correction_editor: ColorCorrectionEditor
var color_scope_editor: ColorScopeEditor
var render_properties: RenderProperties
var render_viewer: RenderViewer

var drawable_rect: DrawableRect
var global_controls: Dictionary[Window, Control]

var full_screen_requested: Array[int] # instance ids
var usable_ress_controllers: Dictionary[UsableRes, Dictionary]
var media_clips_focused: Array[MediaServer.ClipPanel]
var graph_editors_focused: Array[CurveController]

var picking_clip: bool

var auto_save_id: int


func _notification(what: int) -> void:
	if what == NOTIFICATION_WM_CLOSE_REQUEST or what == NOTIFICATION_CRASH:
		popup_save_option_or_save(get_tree().quit)


func _ready_editor_server(editors: Dictionary[StringName, EditorControl]) -> void:
	
	editor_settings.theme.update_colors()
	
	DirAccess.make_dir_absolute(app_data_dir)
	
	main = get_tree().get_current_scene()
	player = editors.player
	media_explorer = editors.media_explorer
	properties = editors.properties
	color_correction_editor = editors.color_correction
	color_scope_editor = editors.color_scope
	time_line2 = editors.time_line2
	render_properties = editors.render_properties
	render_viewer = editors.render_viewer
	
	MediaServer.ClipPanel.timeline = time_line2
	Layer2.timeline = time_line2
	
	drawable_rect = get_tree().get_first_node_in_group(&"drawable_rect")
	
	for editor_name: StringName in editors:
		editors[editor_name]._ready_editor()
	
	update_from_theme_settings()
	
	update_popup_menus()
	
	popup_version_panel()
	
	ProjectServer2.project_opened.connect(_on_project_server2_project_opened)
	
	popup_menu_recent.id_pressed.connect(_on_popup_menu_recent_id_pressed)
	popup_menu_layout.id_pressed.connect(_on_popup_menu_layout_id_pressed)
	popup_menu_docks.id_pressed.connect(_on_popup_menu_docks_id_pressed)
	
	editor_settings.edit.res_changed.connect(update_from_edit_settings)
	editor_settings.performance.res_changed.connect(update_from_performance_settings)
	editor_settings.theme.res_changed.connect(update_from_theme_settings)
	
	get_window().focus_entered.connect(_on_window_focus_entered)
	get_window().files_dropped.connect(_on_window_files_dropped)
	
	is_editor_server_ready = true
	editor_server_ready.emit()


func update_popup_menus() -> void:
	
	popup_menu_recent.clear()
	popup_menu_layout.clear()
	popup_menu_docks.clear()
	
	var preset_layouts: Array[LayoutRootInfo] = main.preset_layouts
	var custom_layouts: Array[LayoutRootInfo] = main.custom_layouts
	var editors: Dictionary[StringName, EditorControl] = main.editors
	
	for idx: int in range(editor_state.recent_projects.size() - 1, -1, -1):
		var path: String = editor_state.recent_projects[idx]
		popup_menu_recent.add_item(path)
	
	var idx: int
	
	for layout: LayoutRootInfo in preset_layouts:
		popup_menu_layout.add_item(layout.layout_name)
		popup_menu_layout.set_item_as_radio_checkable(idx, true)
		popup_menu_layout.set_item_metadata(idx, layout)
		idx += 1
	
	popup_menu_layout.add_separator(); idx += 1
	
	for layout: LayoutRootInfo in custom_layouts:
		popup_menu_layout.add_item(layout.layout_name)
		popup_menu_layout.set_item_as_radio_checkable(idx, true)
		popup_menu_layout.set_item_metadata(idx, layout)
		idx += 1
	
	idx = 0
	
	for editor_name: StringName in editors:
		popup_menu_docks.add_item(editor_name.capitalize())
		popup_menu_docks.set_item_as_radio_checkable(idx, true)
		popup_menu_docks.set_item_metadata(idx, editor_name)
		idx += 1
	
	update_popup_menu_layout_item_checked(main.curr_layout)
	update_popup_menu_docks_items_checked(main.editors)


func update_popup_menu_layout_item_checked(curr_layout: LayoutRootInfo) -> void:
	for idx: int in popup_menu_layout.item_count:
		popup_menu_layout.set_item_checked(idx, popup_menu_layout.get_item_metadata(idx) == curr_layout)

func update_popup_menu_docks_items_checked(editors: Dictionary[StringName, EditorControl]) -> void:
	for idx: int in popup_menu_docks.item_count:
		var editor_name: StringName = popup_menu_docks.get_item_metadata(idx)
		var editor: EditorControl = editors[editor_name]
		popup_menu_docks.set_item_checked(idx, editor.is_visible_in_tree())


func update_title() -> void:
	var title:= "HudMod (%s)" % ProjectServer2.project_path
	if ProjectServer2.saved_version != ProjectServer2.undo_redo.get_version():
		title += " *"
	get_window().title = title




# ---------------------------------------------------

func togggle_full_screen_request(id: int) -> void:
	if full_screen_requested.has(id): full_screen_requested.erase(id)
	else: full_screen_requested.append(id)
	update_window_mode()

func update_window_mode() -> void:
	get_window().mode = Window.MODE_FULLSCREEN if full_screen_requested.size() > 0 else Window.MODE_MAXIMIZED

func shortcuts_cond_func() -> bool:
	var focus_ctrl: Control = get_viewport().gui_get_focus_owner()
	var cond1:= WindowManager.popuped_windows.is_empty()
	var cond2:= not version_window and not replace_paths_window
	var cond3:= (focus_ctrl == null or (focus_ctrl is not LineEdit and focus_ctrl is not TextEdit))
	return cond1 and cond2 and cond3

func layers_body_shortcut_node_cond_func() -> bool:
	return shortcuts_cond_func() and graph_editors_focused.is_empty()


# Controllers Handling
# ---------------------------------------------------

func set_usable_res_controllers(usable_res: UsableRes, usable_ress: Array[UsableRes], edit_cont: EditContainer, properties_containers: Dictionary[StringName, Control], ui_profile: UIProfile) -> void:
	usable_ress_controllers[usable_res] = {
		&"usable_ress": usable_ress,
		&"edit_cont": edit_cont,
		&"properties_boxes_containers": properties_containers,
		&"ui_profile": ui_profile
	}

func has_usable_res_controllers(usable_res: UsableRes) -> bool:
	if usable_ress_controllers.has(usable_res):
		if usable_ress_controllers[usable_res].edit_cont:
			return true
		usable_ress_controllers.erase(usable_res)
	return false

func clear_usable_res_controllers(usable_res: UsableRes) -> void:
	usable_ress_controllers.erase(usable_res)

func get_usable_res_shared_ress(usable_res: UsableRes) -> Array[UsableRes]:
	return usable_ress_controllers[usable_res].usable_ress

func get_usable_res_main_edit(usable_res: UsableRes) -> EditContainer:
	return usable_ress_controllers[usable_res].edit_cont

func get_usable_res_controllers(usable_res: UsableRes) -> Dictionary[StringName, Control]:
	return usable_ress_controllers[usable_res].properties_boxes_containers

func get_usable_res_ui_profile(usable_res: UsableRes) -> UIProfile:
	return usable_ress_controllers[usable_res].ui_profile

func update_usable_res_ui_profile(usable_res: UsableRes) -> void:
	get_usable_res_ui_profile(usable_res).update()

func get_usable_res_property_controller(usable_res: UsableRes, property_key: StringName) -> Control:
	if usable_ress_controllers.has(usable_res):
		var curr_properties_containers: Dictionary = usable_ress_controllers[usable_res].properties_boxes_containers
		var property_container: Variant = curr_properties_containers[property_key]
		if not is_instance_valid(property_container):
			return null
		return property_container
	return null

func update_usable_res_property_controller(usable_res: UsableRes, property_key: StringName, new_val: Variant, has_keyframe: bool) -> void:
	var property_container: EditContainer = get_usable_res_property_controller(usable_res, property_key)
	if property_container:
		property_container.set_curr_value_manually(new_val)
		property_container.set_controller_curr_value_manually(new_val)
		property_container.set_keyframe_method(int(has_keyframe))

func set_usable_res_property_controller_keyframe_method(usable_res: UsableRes, property_key: StringName, has_keyframe: bool) -> void:
	var property_container:= get_usable_res_property_controller(usable_res, property_key)
	if property_container: property_container.set_keyframe_method(int(has_keyframe))


func toggle_fullscreen() -> void:
	togggle_full_screen_request(get_instance_id())

func auto_save(id: int) -> void:
	await get_tree().create_timer(editor_settings.edit.auto_save_interval * 60.).timeout
	if auto_save_id != id:
		return
	ProjectServer2.save()
	auto_save(id)

func use_high_quality() -> bool:
	return Renderer.is_working or not editor_settings.performance.low_quality_for_playback


# Directories: Save Load Handling
# ---------------------------------------------------

func make_dir_abs(path: String) -> Error:
	return DirAccess.make_dir_recursive_absolute(path)

func make_dirs_abs(paths: PackedStringArray) -> Array[Error]:
	var errors: Array[Error]
	for path: String in paths:
		errors.append(DirAccess.make_dir_recursive_absolute(path))
	return errors

func remove_abs(path: String) -> Error:
	return DirAccess.remove_absolute(path)

func load_custom_layouts() -> Array[LayoutRootInfo]:
	make_dir_abs(editor_layout_path)
	
	var result: Array[LayoutRootInfo]
	for file_name: StringName in DirAccess.get_files_at(editor_layout_path):
		var layout: LayoutRootInfo = ResourceLoader.load(editor_layout_path + file_name)
		layout.set_meta(&"id", file_name.get_file().trim_suffix(&".res"))
		result.append(layout)
	return result

func save_custom_layouts(custom_layouts: Array[LayoutRootInfo], clear_old: bool = false, generate_ids: bool = true) -> void:
	make_dir_abs(editor_layout_path)
	
	var used_ids: PackedStringArray
	if clear_old: clear_custom_layouts()
	else: used_ids = DirAccess.get_files_at(editor_layout_path)
	
	for layout: LayoutRootInfo in custom_layouts:
		var id: String
		if generate_ids:
			id = StringHelper.generate_new_id(used_ids, 12)
		else:
			id = layout.get_meta(&"id")
		ResourceSaver.save(layout, str(editor_layout_path, id, ".res"), ResourceSaver.FLAG_COMPRESS)
		layout.set_meta(&"id", id)
		used_ids.append(id)

func remove_custom_layouts(custom_layouts: Array[LayoutRootInfo]) -> void:
	for layout: LayoutRootInfo in custom_layouts:
		var file_name: String = layout.get_meta(&"id") + ".res"
		remove_abs(editor_layout_path + file_name)

func clear_custom_layouts() -> void:
	for file_name: StringName in DirAccess.get_files_at(editor_layout_path):
		remove_abs(editor_layout_path + file_name)

func load_presets(global: bool = false) -> Array[MediaClipRes]:
	var target_dir: String = get_presets_path(global)
	make_dir_abs(target_dir)
	var result: Array[MediaClipRes]
	for file_name: StringName in DirAccess.get_files_at(target_dir):
		var media_res: Resource = ResourceLoader.load(editor_layout_path + file_name)
		if media_res is MediaClipRes:
			result.append(media_res)
	return result

func create_presets(presets: Array[MediaClipRes], global: bool = false) -> PackedStringArray:
	var target_path: String = get_presets_path(global)
	make_dir_abs(target_path)
	var used_ids: PackedStringArray = DirAccess.get_files_at(target_path)
	var save_paths: PackedStringArray
	for preset_media_res: MediaClipRes in presets:
		var id: String = StringHelper.generate_new_id(used_ids, 12)
		var save_path: String = str(target_path, id, ".res")
		MediaServer.store_not_saved_resource(save_path, preset_media_res)
		used_ids.append(id)
		save_paths.append(save_path)
	return save_paths

func get_presets_path(global: bool) -> String:
	return GlobalServer.global_preset_path if global else ProjectServer2.project_preset_path

func get_media_path(global: bool) -> String:
	return GlobalServer.global_media_path if global else ProjectServer2.project_media_path

func get_ids_from_pathes(pathes: PackedStringArray) -> PackedStringArray:
	var used_ids: PackedStringArray
	for path: String in pathes:
		used_ids.append(path.get_file().split(".")[0])
	return used_ids

var latest_import_paths: PackedStringArray

func scan_media_existent() -> void:
	
	if ProjectServer2.project_res == null:
		return
	
	var project_imp_sys: DisplayFileSystemRes = ProjectServer2.import_file_system
	var project_pres_sys: DisplayFileSystemRes = ProjectServer2.preset_file_system
	var global_imp_sys: DisplayFileSystemRes = GlobalServer.import_file_system
	var global_pres_sys: DisplayFileSystemRes = GlobalServer.preset_file_system
	
	if not project_imp_sys or not global_imp_sys:
		return
	
	MediaCache.load_media_cache_from_file_system(project_imp_sys)
	MediaCache.load_media_cache_from_file_system(global_imp_sys)
	
	project_imp_sys.check_for_discard_paths()
	global_imp_sys.check_for_discard_paths()
	
	var project_import_paths: PackedStringArray = project_imp_sys.get_files_paths()
	var project_preset_paths: PackedStringArray = project_pres_sys.get_files_paths()
	
	var global_import_paths: PackedStringArray = global_imp_sys.get_files_paths()
	var global_preset_paths: PackedStringArray = global_pres_sys.get_files_paths()
	
	var all_import_paths: PackedStringArray = project_import_paths + global_import_paths
	
	var disk_paths_not_exists: PackedStringArray
	
	for import_path: String in all_import_paths:
		if not FileAccess.file_exists(import_path):
			disk_paths_not_exists.append(import_path)
	
	if disk_paths_not_exists:
		if not replace_paths_window:
			popup_replace_paths(disk_paths_not_exists)
		return
	elif replace_paths_window:
		replace_paths_window.queue_free()
	
	if all_import_paths == latest_import_paths: return
	latest_import_paths = all_import_paths
	
	ProjectServer2.project_res.root_clip_res.update_layers_paths_deep()
	#var paths_unavailable: PackedStringArray = ProjectServer2.project_res.root_clip_res.check_layers_for_paths_deep(all_import_paths)
	#ProjectServer2.project_res.root_clip_res.erase_layers_paths_deep(paths_unavailable)
	
	media_explorer.import_box.update()
	media_explorer.preset_box.update()

func replace_paths(paths_for_replace: Dictionary[String, String], discard_option: bool) -> void:
	ProjectServer2.import_file_system.replace_paths(paths_for_replace, discard_option)
	GlobalServer.import_file_system.replace_paths(paths_for_replace, discard_option)
	format_paths(paths_for_replace)
	MediaCache.video_contexts_update_max_cache_size()
	media_explorer.import_box.update()

func discard_paths(paths: PackedStringArray) -> void:
	ProjectServer2.import_file_system.discard_paths(paths)
	GlobalServer.import_file_system.discard_paths(paths)

func format_paths(paths_for_format: Dictionary[String, String]) -> void:
	ProjectServer2.project_res.root_clip_res.format_paths_deep(paths_for_format)
	ProjectServer2.preset_file_system.preset_media_ress_format_paths(paths_for_format)
	GlobalServer.preset_file_system.preset_media_ress_format_paths(paths_for_format)


func get_import_file_system(global: bool) -> DisplayFileSystemRes: return GlobalServer.import_file_system if global else ProjectServer2.import_file_system
func get_preset_file_system(global: bool) -> DisplayFileSystemRes: return GlobalServer.preset_file_system if global else ProjectServer2.preset_file_system


# Popup Windows
# ---------------------------------------------------

var version_window: Window

func popup_version_panel() -> void:
	
	var new_project_res: ProjectRes = ProjectRes.new()
	
	var bg_color: Color = IS.color_base_dark.darkened(.3)
	
	var gradient_mat:= ShaderMaterial.new()
	gradient_mat.shader = preload("res://UI&UX/Shader/ShaderTranspGrad.gdshader")
	gradient_mat.set_shader_parameter(&"flip", true)
	gradient_mat.set_shader_parameter(&"color", bg_color)
	
	version_window = Window.new()
	version_window.content_scale_factor = editor_settings.theme.content_scale
	version_window.size = Vector2i(800, 750)
	version_window.borderless = true
	version_window.exclusive = true
	WindowManager.popup_custom_window(version_window)
	version_window.popup_centered()
	
	var vsplit_cont: SplitContainer = IS.create_split_container(0, true)
	vsplit_cont.dragger_visibility = SplitContainer.DRAGGER_HIDDEN_COLLAPSED
	
	var version_rect: TextureRect = IS.create_texture_rect(version_info.version_banner, {expand_mode = TextureRect.EXPAND_IGNORE_SIZE, stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_COVERED})
	var gradient_rect: ColorRect = IS.create_color_rect(Color.WHITE, {material = gradient_mat, custom_minimum_size = Vector2(.0, 150.)})
	
	var version_label: Label = Label.new()
	version_label.text = version_info.version_name
	version_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	version_label.custom_minimum_size = Vector2(100., 60.)
	version_label.add_theme_color_override(&"font_color", Color.BLACK)
	
	var banner_owner_btn: LinkButton = LinkButton.new()
	banner_owner_btn.text = "A photo by %s" % version_info.banner_owner
	banner_owner_btn.uri = version_info.banner_owner_link
	
	var support_btn: LinkButton = LinkButton.new()
	support_btn.text = "Support HudMod developement ❤️"
	support_btn.uri = version_info.support_link
	
	var bg_rect: ColorRect = IS.create_color_rect(bg_color)
	var margin_cont: MarginContainer = IS.create_margin_container()
	var body_panel: PanelContainer = IS.create_panel_container(Vector2.ZERO, IS.style_dark)
	var margin_cont2: MarginContainer = IS.create_margin_container(8, 8, 8, 8)
	var hsplit_cont: SplitContainer = IS.create_split_container(0)
	
	var left_vsplit_cont: SplitContainer = IS.create_split_container(2, true)
	var recent_projs_list: ItemList = IS.create_item_list([])
	var open_btn: Button = IS.create_button("Open other")
	
	var right_vbox_cont: SplitContainer = IS.create_split_container(2, true)
	var path_edit: EditContainer = IS.create_string_edit("project_path", OS.get_system_dir(OS.SYSTEM_DIR_DOCUMENTS), "", IS.StringControllerType.TYPE_OPEN_DIR)
	var project_res_edit: EditContainer = new_project_res.create_custom_edit("base_informations", new_project_res, [])
	var new_btn: Button = IS.create_button("Create new project")
	
	version_window.add_child(vsplit_cont)
	
	# Top Side (Banner)
	vsplit_cont.add_child(version_rect)
	version_rect.add_child(gradient_rect)
	version_rect.add_child(version_label)
	gradient_rect.add_child(support_btn)
	gradient_rect.add_child(banner_owner_btn)
	
	# Bottom Side (Control)
	vsplit_cont.add_child(bg_rect)
	bg_rect.add_child(margin_cont)
	margin_cont.add_child(body_panel)
	body_panel.add_child(margin_cont2)
	margin_cont2.add_child(hsplit_cont)
	
	hsplit_cont.add_child(left_vsplit_cont)
	left_vsplit_cont.add_child(recent_projs_list)
	left_vsplit_cont.add_child(open_btn)
	
	hsplit_cont.add_child(right_vbox_cont)
	right_vbox_cont.add_child(path_edit)
	right_vbox_cont.add_child(project_res_edit)
	right_vbox_cont.add_child(new_btn)
	
	IS.expand(version_rect, true, true)
	IS.expand(bg_rect, true, true)
	IS.expand(left_vsplit_cont)
	IS.expand(right_vbox_cont)
	IS.expand(project_res_edit, true, true)
	
	gradient_rect.set_anchors_and_offsets_preset(Control.PRESET_BOTTOM_WIDE)
	version_label.set_anchors_and_offsets_preset(Control.PRESET_TOP_LEFT)
	banner_owner_btn.set_anchors_and_offsets_preset(Control.PRESET_BOTTOM_LEFT)
	support_btn.set_anchors_and_offsets_preset(Control.PRESET_BOTTOM_RIGHT)
	
	gradient_rect.position.y -= 150.
	banner_owner_btn.position.x += 10.
	support_btn.position.x -= 10.
	
	for idx: int in range(editor_state.recent_projects.size() - 1, -1, -1):
		var path: String = editor_state.recent_projects[idx]
		recent_projs_list.add_item(path)
	
	var new_method: Callable = func() -> void:
		var line_edit: LineEdit = path_edit.controller
		var dir: String = line_edit.text + "/" + new_project_res.project_name
		ProjectServer2.new_project(new_project_res, dir)
	
	recent_projs_list.item_activated.connect(func(idx: int) -> void:
		if not await ProjectServer2.open_project(recent_projs_list.get_item_text(idx)):
			editor_state.recent_projects.erase(recent_projs_list.get_item_text(idx))
			recent_projs_list.remove_item(idx)
			ResourceSaver.save(editor_state, editor_state_path)
			update_popup_menus()
	)
	open_btn.pressed.connect(popup_open_project)
	new_btn.pressed.connect(new_method)


func popup_learn() -> void:
	pass


func popup_about() -> void:
	var cont: MarginContainer = WindowManager.popup_window_base(get_window(), Vector2i(900, 600), "About HudMod")
	var box_cont: BoxContainer = IS.create_box_container(6, true)
	
	var win: Window = cont.get_window()
	win.max_size = Vector2i(1200, 900)
	
	var header_split_cont: SplitContainer = IS.create_split_container()
	var icon_rect: TextureRect = IS.create_texture_rect(preload("res://Asset/Icons/App/logo2-mid.png"), {})
	var copyright_label: Label = IS.create_label(str("HudMod Video Editor v%s" % version_info.version_name, "\n", version_info.copyright_text), "", IS.label_settings_main, {alignment = HORIZONTAL_ALIGNMENT_LEFT, vertical_alignment = VERTICAL_ALIGNMENT_CENTER})
	icon_rect.custom_minimum_size.x = 400.
	icon_rect.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	icon_rect.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	
	var menu: Menu = IS.create_menu([
		MenuOption.new("Q & A"),
		MenuOption.new("Authors"),
		MenuOption.new("Supporters"),
		MenuOption.new("License"),
		MenuOption.new("Third-party Licenses")
	])
	
	var body_panel: PanelContainer = IS.create_panel_container(Vector2.ZERO, IS.style_body)
	var body_cont: MarginContainer = IS.create_margin_container(8, 8, 8, 8)
	var scroll_cont: ScrollContainer = IS.create_scroll_container()
	
	header_split_cont.custom_minimum_size.y = 200.
	IS.expand(body_panel, true, true)
	IS.expand(copyright_label, true, true)
	
	header_split_cont.add_child(icon_rect)
	header_split_cont.add_child(copyright_label)
	
	var sections: Array[Node] = [
		_section_Q_and_A(),
		_section_authors(),
		await _section_supporters(),
		_section_license(),
		_section_third_party_licenses()
	]
	
	for section: Control in sections:
		IS.expand(section, true, true)
	
	IS.add_children(scroll_cont, sections)
	
	if not cont:
		return
	
	body_cont.add_child(scroll_cont)
	body_panel.add_child(body_cont)
	box_cont.add_child(header_split_cont)
	box_cont.add_child(menu)
	box_cont.add_child(body_panel)
	cont.add_child(box_cont)
	
	var focus_at: Callable = func(idx: int) -> void:
		for section_idx: int in scroll_cont.get_child_count():
			var section_ctrl: Control = scroll_cont.get_child(section_idx)
			section_ctrl.visible = section_idx == idx
	
	menu.focus_index_changed.connect(focus_at)
	
	focus_at.call(0)


func _section_Q_and_A() -> Control:
	var label: RichTextLabel = RichTextLabel.new()
	label.add_theme_color_override(&"default_color", IS.color_label)
	label.bbcode_enabled = true
	label.text = version_info.questions_and_answers.format({
		"website_link": version_info.website_link,
		"itch_link": version_info.itch_link,
		"discord_link": version_info.discord_link,
		"support_link": version_info.support_link
	})
	label.meta_clicked.connect(func(meta: Variant) -> void: OS.shell_open(str(meta)))
	return label

func _section_authors() -> Control:
	var cont: BoxContainer = IS.create_box_container(8, true, {})
	IS.add_children(cont, [
		_create_text_content_with_header("Project Founder", [version_info.project_founder]),
		_create_text_content_with_header("Lead Developer", [version_info.lead_developer]),
		_create_text_content_with_header("Developers", version_info.developers)
	])
	return cont

func _section_supporters() -> Control:
	
	if not is_supporters_dict_loaded:
		
		var http_request:= HTTPRequest.new()
		add_child(http_request)
		http_request.request_completed.connect(
			func(result: int, response_code: int, headers: PackedStringArray, body: PackedByteArray) -> void:
				if response_code == 200:
					var json: JSON = JSON.new()
					var parse_result: Error = json.parse(body.get_string_from_utf8())
					
					if parse_result == OK:
						var response: Dictionary = json.get_data()
						for rank: String in response:
							if rank not in SUPPORTERS_INFO:
								continue
							supporters.append({&"rank": StringName(rank), &"supporters": response[rank]})
						is_supporters_dict_loaded = true
				
				http_request.queue_free()
		)
		var error: Error = http_request.request(supporters_url)
		await http_request.request_completed
	
	supporters.sort_custom(
		func(a: Dictionary, b: Dictionary) -> bool:
			return SUPPORTERS_INFO[a.rank].priority < SUPPORTERS_INFO[b.rank].priority
	)
	
	var supporters_box_cont: BoxContainer = IS.create_box_container(8, true, {})
	
	for supp_dict: Dictionary in supporters:
		
		var rank: StringName = supp_dict.rank
		var rank_supporters: Array = supp_dict.supporters
		var rank_info: Dictionary = SUPPORTERS_INFO[rank]
		
		var bg_color: Color = rank_info.color
		
		var style: StyleBoxFlat = IS.style_panel.duplicate()
		style.bg_color = bg_color
		
		var rank_panel: PanelContainer = IS.create_panel_container(Vector2.ZERO, style)
		var rank_label: Label = Label.new()
		rank_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		rank_label.text = rank
		rank_label.add_theme_color_override(&"font_color", Color.GRAY if bg_color.get_luminance() < .5 else Color.BLACK)
		supporters_box_cont.add_child(rank_panel)
		
		supporters_box_cont.add_child(rank_panel)
		rank_panel.add_child(rank_label)
		
		for member_data: Dictionary in rank_supporters:
			
			var link: Variant = member_data.link
			
			var name_label: Label = IS.create_label(member_data.name)
			
			if link is String and not link.is_empty():
				link = link.strip_edges()
				var link_btn: IS.CustomTextureButton = IS.create_texture_button(preload("res://Asset/Icons/external-link.png"))
				link_btn.set_anchors_and_offsets_preset(Control.PRESET_CENTER_RIGHT)
				name_label.add_child(link_btn)
				link_btn.pressed.connect(OS.shell_open.bind(link))
			
			supporters_box_cont.add_child(name_label)
	
	return supporters_box_cont

func _section_license() -> Control:
	var label: RichTextLabel = RichTextLabel.new()
	label.add_theme_color_override(&"default_color", IS.color_label)
	label.bbcode_enabled = true
	label.text = version_info.license
	label.meta_clicked.connect(func(meta: Variant) -> void: OS.shell_open(str(meta)))
	return label

func _section_third_party_licenses() -> Control:
	var label: RichTextLabel = RichTextLabel.new()
	label.add_theme_color_override(&"default_color", IS.color_label)
	label.bbcode_enabled = true
	label.text = version_info.thirdparty_licenses
	return label

func _create_text_content_with_header(header: String, content: Array[String]) -> Category:
	var category: Category = IS.create_category(true, header, Color.TRANSPARENT, Vector2.ZERO, false)
	var label: RichTextLabel = RichTextLabel.new()
	
	label.add_theme_color_override(&"default_color", IS.color_label)
	label.bbcode_enabled = true
	label.fit_content = true
	label.text = "[center]"
	for text: String in content: label.text += text + "\n"
	category.add_content(label)
	IS.expand(label)
	
	category.is_expanded = true
	label.meta_clicked.connect(func(meta: Variant) -> void: OS.shell_open(str(meta)))
	
	return category



func popup_new_project() -> void:
	var project_res:= ProjectRes.new()
	
	var path_edit: EditContainer = IS.create_string_edit("project_path", OS.get_system_dir(OS.SYSTEM_DIR_DOCUMENTS), "", IS.StringControllerType.TYPE_OPEN_DIR)
	var project_res_edit: EditContainer = project_res.create_custom_edit("base_informations", project_res)
	
	var accept_method: Callable = func() -> void:
		var line_edit: LineEdit = path_edit.controller
		var dir: String = line_edit.text + "/" + project_res.project_name
		ProjectServer2.new_project(project_res, dir)
	
	var win_cont: BoxContainer = WindowManager.popup_accept_window(get_window(), Vector2(600., 400.), "New Project", accept_method)
	var win: Window = win_cont.get_window()
	
	win_cont.add_child(path_edit)
	win_cont.add_child(project_res_edit)

func popup_open_project(on_project_opened_successfully: Callable = Callable()) -> void:
	
	var file_dialog: FileDialog = WindowManager.create_file_dialog_window(get_window(), FileDialog.FILE_MODE_OPEN_FILE, [".res"], Vector2.ZERO, "Select Project")
	file_dialog.current_dir = OS.get_system_dir(OS.SYSTEM_DIR_DOCUMENTS)
	file_dialog.file_selected.connect(
		func _on_file_dialog_file_selected(path: String) -> void:
			if not path.ends_with(".res"):
				push_message("The file must end with '.res'", MessageMode.MESSAGE_MODE_WARNING)
				return
			popup_save_option_or_save(ProjectServer2.open_project.bind(path.get_base_dir()), "Save & Open")
	)
	file_dialog.popup_file_dialog()


func popup_save_as() -> void:
	var file_dialog: FileDialog = WindowManager.create_file_dialog_window(get_window(), FileDialog.FILE_MODE_SAVE_FILE, [], Vector2.ZERO, "Save As")
	file_dialog.current_dir = OS.get_system_dir(OS.SYSTEM_DIR_DOCUMENTS)
	file_dialog.file_selected.connect(
		func _on_file_dialog_file_selected(new_dir_path: String) -> void:
			ProjectServer2.save_as(new_dir_path)
	)
	file_dialog.popup_file_dialog()


var replace_paths_window: Window

func popup_replace_paths(paths: PackedStringArray, discard_option: bool = true, custom_popup: bool = false) -> WindowManager.AcceptWindow:
	var paths_for_replace: Dictionary[String, String] = {}
	
	var window_cont: BoxContainer = WindowManager.popup_accept_window(
		get_window(),
		Vector2(900, 500),
		"Replace unexistent paths",
		replace_paths.bind(paths_for_replace, discard_option),
		func() -> void: if discard_option: discard_paths(paths)
	)
	
	var window: WindowManager.AcceptWindow = window_cont.get_window()
	window.accept_button.text = "Replace"
	window.cancel_button.text = "Discard"
	
	window_cont.alignment = BoxContainer.ALIGNMENT_BEGIN
	
	for path: String in paths:
		
		if paths_for_replace.has(path):
			continue
		
		var new_path: String = ""
		
		var type: int = MediaServer.get_media_type_from_path(path)
		var classname: StringName
		match type:
			0: classname = &"ImageClipRes"
			1: classname = &"VideoClipRes"
			2: classname = &"AudioClipRes"
		var type_info: Dictionary = MediaServer.object_clip_info[classname]
		
		var path_edit: EditContainer = IS.create_string_edit(path, new_path, "Choose a New path", 2, MediaServer.ARR_MEDIA_EXTENSIONS[type])
		
		var icon_rect: TextureRect = IS.create_texture_rect(type_info.icon, {modulate = type_info.color, custom_minimum_size = Vector2(24., .0), stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED})
		var valid_path_rect: TextureRect = IS.create_texture_rect(null, {custom_minimum_size = Vector2(24., .0), stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED})
		
		icon_rect.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		icon_rect.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
		
		var on_update_path_func: Callable = func(usable_res: UsableRes, key: StringName, val: String) -> void:
			paths_for_replace[path] = val
			
			var cond1: bool = FileAccess.file_exists(val)
			var cond2: bool = MediaServer.get_media_type_from_path(val) == type
			valid_path_rect.texture = IS.TEXTURE_CHECK if cond1 and cond2 else IS.TEXTURE_X_MARK
		
		on_update_path_func.call(null, &"", new_path)
		
		path_edit.header_cont.add_child(icon_rect)
		path_edit.header_cont.add_child(valid_path_rect)
		path_edit.val_changed.connect(on_update_path_func)
		
		window_cont.add_child(path_edit)
		
		paths_for_replace[path] = new_path
	
	if not custom_popup:
		replace_paths_window = window
	
	return window


func popup_editor_settings() -> void:
	
	var settings_options: Array = [
		MenuOption.new("Edit", preload("res://Asset/Icons/video-editor.png")),
		MenuOption.new("Performance & Caching", preload("res://Asset/Icons/speedometer.png")),
		MenuOption.new("Shortcuts", preload("res://Asset/Icons/keyboard.png")),
		MenuOption.new("Theme", preload("res://Asset/Icons/theme.png"))
	]
	
	var win_cont: MarginContainer = WindowManager.popup_window_base(get_window(), Vector2i(1200, 600), "Editor Settings")
	var split_cont: SplitContainer = IS.create_split_container()
	
	var left_panel: PanelContainer = IS.create_panel_container(Vector2(350., .0), IS.style_body)
	var left_margin: MarginContainer = IS.create_margin_container(8, 8, 8, 8)
	var left_menu: Menu = IS.create_menu(settings_options, true)
	
	var right_panel: PanelContainer = IS.create_panel_container(Vector2.ZERO, IS.style_body)
	var right_margin: MarginContainer = IS.create_margin_container(8, 8, 8, 8)
	
	left_margin.add_child(left_menu)
	left_panel.add_child(left_margin)
	split_cont.add_child(left_panel)
	
	right_panel.add_child(right_margin)
	split_cont.add_child(right_panel)
	
	win_cont.add_child(split_cont)
	
	var settings: AppEditorSettings = editor_settings
	var arr_of_settings: Array[UsableRes] = [settings.edit, settings.performance, settings.shortcuts, settings.theme]
	
	for idx: int in arr_of_settings.size():
		var idx_settings: UsableRes = arr_of_settings[idx]
		if not idx_settings: continue
		
		var sett_split_cont: SplitContainer = IS.create_split_container(2, true)
		var search_line: LineEdit = IS.create_line_edit("Filter Settings", "", IS.TEXTURE_SEARCH)
		var scroll_cont: ScrollContainer = IS.create_scroll_container()
		var idx_settings_edit: EditContainer = UsableRes.create_custom_edit(settings_options[idx].text, idx_settings, [], search_line)
		idx_settings_edit.show()
		
		sett_split_cont.add_child(search_line)
		
		sett_split_cont.add_child(scroll_cont)
		scroll_cont.add_child(idx_settings_edit)
		
		right_margin.add_child(sett_split_cont)
		
		IS.expand(idx_settings_edit, true, true)
	
	left_menu.buttons_container.alignment = BoxContainer.ALIGNMENT_BEGIN
	
	var set_focused_idx: Callable = func(idx: int) -> void:
		for ctrl: Control in right_margin.get_children(): ctrl.hide()
		var shown_ctrl: Control = right_margin.get_child(idx)
		shown_ctrl.show()
	
	set_focused_idx.call(0)
	left_menu.focus_index_changed.connect(set_focused_idx)
	
	win_cont.get_window().close_requested.connect(ResourceSaver.save.bind(editor_settings, editor_settings_path))



func popup_save_option_or_save(method: Callable, accept_text: String = "Save & Quit", cancel_text: String = "Don't Save") -> void:
	
	if not ProjectServer2.project_res:
		method.call()
		return
	
	if ProjectServer2.saved_version == ProjectServer2.undo_redo.get_version():
		method.call()
		return
	
	if editor_settings.edit.auto_save:
		ProjectServer2.save();
		method.call()
		return
	
	var save_and_close: Callable = func() -> void: ProjectServer2.save(); method.call()
	var discard_and_close: Callable = func() -> void: method.call()
	
	var win_cont: BoxContainer = WindowManager.popup_accept_window(get_window(), Vector2(300., 150.), "Please Comfirm", save_and_close)
	var win: WindowManager.AcceptWindow = win_cont.get_window()
	win.accept_button.text = accept_text
	win.cancel_button.text = cancel_text
	win.cancel_button.pressed.connect(discard_and_close)
	
	win_cont.add_child(IS.create_label("Save changes before quitting ?"))


func report_bugs() -> void: OS.shell_open(version_info.discord_link)

func go_to_community() -> void: OS.shell_open(version_info.discord_link)




func push_message(text: String, message_mode: MessageMode = MessageMode.MESSAGE_MODE_ERROR) -> void:
	
	message_history.append({
		&"text": text,
		&"mode": message_mode
	} as Dictionary[StringName, Variant])
	
	var icon: Texture2D
	var style: StyleBoxFlat
	
	match message_mode:
		0: icon = IS.TEXTURE_MESSAGE; style = IS.STYLE_IDLE
		1: icon = IS.TEXTURE_WARNING; style = IS.STYLE_WARNING
		2: icon = IS.TEXTURE_ERROR; style = IS.STYLE_ERROR
	
	var panel_cont: PanelContainer = IS.create_panel_container(Vector2.ZERO, style)
	var timeout_bar: ProgressBar = ProgressBar.new()
	var split_cont: SplitContainer = IS.create_split_container()
	var icon_rect: TextureRect = IS.create_texture_rect(icon)
	var message_label: Label = IS.create_label(text)
	
	panel_cont.custom_minimum_size.x = 400.
	timeout_bar.show_percentage = false
	timeout_bar.value = 100.
	timeout_bar.modulate.a = .5
	IS.expand(timeout_bar, true, true)
	
	split_cont.add_child(icon_rect)
	split_cont.add_child(message_label)
	panel_cont.add_child(timeout_bar)
	panel_cont.add_child(split_cont)
	
	main.messages_container.add_child(panel_cont)
	
	var tween: Tween = create_tween()
	tween.tween_property(timeout_bar, "value", .0, 2.5)
	tween.tween_property(panel_cont, "modulate:a", .0, 1.)
	await tween.finished
	
	panel_cont.queue_free()


# Connections
# ---------------------------------------------------

func update_from_edit_settings() -> void:
	var edit_settings: AppEditRes = editor_settings.edit
	
	player.replay_button.button_pressed = edit_settings.replay
	player.replay_button.update_button()
	
	time_line2.auto_snap = edit_settings.auto_snap
	time_line2.dist_to_snap = edit_settings.snap_strength / 10.
	
	auto_save_id += 1
	if edit_settings.auto_save:
		auto_save(auto_save_id)

func update_from_performance_settings() -> void:
	Scene2.update_viewport()
	RenderFarm.update_pprs()
	MediaCache.video_contexts_clear_video_decoders()
	MediaCache.video_contexts_clear_frames()

func update_from_theme_settings() -> void:
	var content_scale: float = editor_settings.theme.content_scale
	get_window().content_scale_factor = content_scale
	for window: Window in WindowManager.popuped_windows:
		window.content_scale_factor = content_scale


func _on_project_server2_project_opened(project_res: ProjectRes) -> void:
	
	var project_path: String = ProjectServer2.project_path
	var recent: Array[String] = editor_state.recent_projects
	
	while recent.size() > EditorStateRes.MAX_RECENT_PROJECTS:
		recent.remove_at(0)
	
	for idx: int in range(recent.size() - 1, -1, -1):
		var other_path: String = recent[idx]
		if project_path.simplify_path() == other_path.simplify_path():
			recent.remove_at(idx)
	
	recent.append(project_path)
	ResourceSaver.save(editor_state, editor_state_path)
	
	update_from_edit_settings()
	update_from_performance_settings()
	scan_media_existent()
	update_popup_menus()
	update_title()
	
	main.freeze_rect.hide()
	
	if version_window:
		version_window.queue_free()

func _on_popup_menu_recent_id_pressed(id: int) -> void:
	popup_save_option_or_save(
		func() -> void:
			if not await ProjectServer2.open_project(popup_menu_recent.get_item_text(id)):
				editor_state.recent_projects.erase(popup_menu_recent.get_item_text(id))
				ResourceSaver.save(editor_state, editor_state_path)
				update_popup_menus(), "Save & Open"
	)

func _on_popup_menu_layout_id_pressed(id: int) -> void:
	await main.update_curr_layout()
	main.open_layout(popup_menu_layout.get_item_metadata(id))

func _on_popup_menu_docks_id_pressed(id: int) -> void:
	var editor_name: StringName = popup_menu_docks.get_item_metadata(id)
	var header_panel: EditorControl.HeaderPanel = main.editors[editor_name].header_panel
	
	if header_panel.is_visible_in_tree():
		if not header_panel.windowed:
			header_panel.to_window(null, true)
		header_panel.to_layout(null, false)
	else:
		header_panel.to_window(null, false)
	
	update_popup_menu_docks_items_checked(main.editors)


func _on_window_focus_entered() -> void:
	await get_tree().process_frame
	if WindowManager.popuped_windows.is_empty():
		scan_media_existent()

func _on_window_files_dropped(files_pathes: Array[String]) -> void:
	pass



