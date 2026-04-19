extends Node

signal editor_server_ready()

# Constants
# ---------------------------------------------------

const ERR_STRENGTH_COLORS:= [
	Color.WEB_GRAY,
	Color.PALE_GOLDENROD,
	Color.INDIAN_RED
]

# Directory Info
# ---------------------------------------------------

static var app_data_dir: String = OS.get_data_dir() + "/HudMod Video Editor/"

static var editor_path: String = app_data_dir + "editor/"
static var editor_layout_path: String = editor_path + "layout/"
static var editor_settings_path: String = editor_path + "editor_settings.res"
static var editor_state_path: String = editor_path + "editor_state.res"

var is_editor_server_ready: bool


var editor_settings: AppEditorSettings = ResLoadHelper.load_or_save(editor_settings_path, AppEditorSettings)
var editor_state: EditorStateRes = ResLoadHelper.load_or_save(editor_state_path, EditorStateRes)


var message_history: Array[Dictionary]


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

var usable_ress_controllers: Dictionary[UsableRes, Dictionary]

var graph_editors_focused: Array[CurveController]


var auto_save_id: int


func _notification(what: int) -> void:
	if what == NOTIFICATION_WM_CLOSE_REQUEST:
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
	
	update_popup_menus()
	
	popup_version_panel()
	
	ProjectServer2.project_opened.connect(_on_project_server2_project_opened)
	
	popup_menu_recent.id_pressed.connect(_on_popup_menu_recent_id_pressed)
	popup_menu_layout.id_pressed.connect(_on_popup_menu_layout_id_pressed)
	popup_menu_docks.id_pressed.connect(_on_popup_menu_docks_id_pressed)
	
	editor_settings.edit.res_changed.connect(update_from_edit_settings)
	editor_settings.performance.res_changed.connect(update_from_performance_settings)
	
	get_window().focus_entered.connect(on_window_focus_entered)
	get_window().files_dropped.connect(on_window_files_dropped)
	
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
	get_window().title = "HudMod (%s)" % ProjectServer2.project_path


# ---------------------------------------------------

func layers_body_shortcut_node_cond_func() -> bool:
	return graph_editors_focused.is_empty()

# Controllers Handling
# ---------------------------------------------------

func set_usable_res_controllers(usable_res: UsableRes, usable_ress: Array[UsableRes], edit_box_container: IS.EditBoxContainer, properties_containers: Dictionary[StringName, Control], ui_profile: UIProfile) -> void:
	usable_ress_controllers[usable_res] = {
		&"usable_ress": usable_ress,
		&"edit_box_container": edit_box_container,
		&"properties_boxes_containers": properties_containers,
		&"ui_profile": ui_profile
	}

func has_usable_res_controllers(usable_res: UsableRes) -> bool:
	if usable_ress_controllers.has(usable_res):
		if usable_ress_controllers[usable_res].edit_box_container:
			return true
		usable_ress_controllers.erase(usable_res)
	return false

func clear_usable_res_controllers(usable_res: UsableRes) -> void:
	usable_ress_controllers.erase(usable_res)

func get_usable_res_shared_ress(usable_res: UsableRes) -> Array[UsableRes]:
	return usable_ress_controllers[usable_res].usable_ress

func get_usable_res_main_edit(usable_res: UsableRes) -> IS.EditBoxContainer:
	return usable_ress_controllers[usable_res].edit_box_container

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
	var property_container:= get_usable_res_property_controller(usable_res, property_key)
	if property_container:
		property_container.set_controller_val_manually(new_val)
		property_container.set_keyframe_method(int(has_keyframe))

func set_usable_res_property_controller_keyframe_method(usable_res: UsableRes, property_key: StringName, has_keyframe: bool) -> void:
	var property_container:= get_usable_res_property_controller(usable_res, property_key)
	if property_container: property_container.set_keyframe_method(int(has_keyframe))



func toggle_fullscreen() -> void:
	var window: Window = get_window()
	if window.mode == Window.MODE_FULLSCREEN: window.mode = Window.MODE_MAXIMIZED
	else: window.mode = Window.MODE_FULLSCREEN

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
	var save_pathes: PackedStringArray
	for preset_media_res: MediaClipRes in presets:
		var id: String = StringHelper.generate_new_id(used_ids, 12)
		var save_path: String = str(target_path, id, ".res")
		MediaServer.store_not_saved_resource(save_path, preset_media_res)
		used_ids.append(id)
		save_pathes.append(save_path)
	return save_pathes

func get_presets_path(global: bool) -> String:
	return GlobalServer.global_preset_path if global else ProjectServer2.project_preset_path

func get_media_path(global: bool) -> String:
	return GlobalServer.global_media_path if global else ProjectServer2.project_media_path

func get_ids_from_pathes(pathes: PackedStringArray) -> PackedStringArray:
	var used_ids: PackedStringArray
	for path: String in pathes:
		used_ids.append(path.get_file().split(".")[0])
	return used_ids

func scan_media_existent() -> void:
	
	if ProjectServer2.project_res == null:
		return
	
	var project_imp_sys:= ProjectServer2.import_file_system
	var project_pres_sys:= ProjectServer2.preset_file_system
	var global_imp_sys:= GlobalServer.import_file_system
	var global_pres_sys:= GlobalServer.preset_file_system
	
	project_imp_sys.check_for_discard_paths()
	global_imp_sys.check_for_discard_paths()
	
	var project_import_paths: PackedStringArray = project_imp_sys.get_files_paths()
	var project_preset_paths: PackedStringArray = project_pres_sys.get_files_paths()
	
	var global_import_paths: PackedStringArray = global_imp_sys.get_files_paths()
	var global_preset_paths: PackedStringArray = global_pres_sys.get_files_paths()
	
	var all_import_paths: PackedStringArray = project_import_paths + global_import_paths
	#var all_preset_paths: PackedStringArray = project_preset_paths + global_preset_paths
	
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
	
	#var global_paths_needed: PackedStringArray = global_pres_sys.preset_media_ress_check_for_paths(global_import_paths)
	
	media_explorer.import_box.update()
	media_explorer.preset_box.update()

func replace_paths(paths_for_replace: Dictionary[String, String], discard_option: bool) -> void:
	ProjectServer2.import_file_system.replace_paths(paths_for_replace, discard_option)
	GlobalServer.import_file_system.replace_paths(paths_for_replace, discard_option)
	format_paths(paths_for_replace)

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
	version_window.size = Vector2i(800, 750)
	version_window.borderless = true
	version_window.always_on_top = true
	WindowManager.add_child(version_window)
	version_window.popup_centered()
	
	var vsplit_cont: SplitContainer = IS.create_split_container(0, true)
	vsplit_cont.dragger_visibility = SplitContainer.DRAGGER_HIDDEN_COLLAPSED
	
	var version_rect: TextureRect = IS.create_texture_rect(main.version_banner, {expand_mode = TextureRect.EXPAND_IGNORE_SIZE, stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_COVERED})
	var gradient_rect: ColorRect = IS.create_color_rect(Color.WHITE, {material = gradient_mat, custom_minimum_size = Vector2(.0, 150.)})
	
	var version_label: Label = Label.new()
	version_label.text = main.version_name
	version_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	version_label.custom_minimum_size = Vector2(100., 60.)
	version_label.add_theme_color_override(&"font_color", Color.BLACK)
	
	var banner_owner_btn: LinkButton = LinkButton.new()
	banner_owner_btn.text = "A photo by %s" % main.banner_owner
	banner_owner_btn.uri = main.banner_owner_link
	
	var support_btn: LinkButton = LinkButton.new()
	support_btn.text = "Support ❤️"
	support_btn.uri = main.support_link
	
	var bg_rect: ColorRect = IS.create_color_rect(bg_color)
	var margin_cont: MarginContainer = IS.create_margin_container()
	var body_panel: PanelContainer = IS.create_panel_container(Vector2.ZERO, IS.style_dark)
	var margin_cont2: MarginContainer = IS.create_margin_container(8, 8, 8, 8)
	var hsplit_cont: SplitContainer = IS.create_split_container(0)
	
	var left_vsplit_cont: SplitContainer = IS.create_split_container(2, true)
	var recent_projs_list: ItemList = IS.create_item_list([])
	var open_btn: Button = IS.create_button("Open other")
	
	var right_vbox_cont: SplitContainer = IS.create_split_container(2, true)
	var path_edit: SplitContainer = IS.create_string_edit("project_path", OS.get_system_dir(OS.SYSTEM_DIR_DOCUMENTS), "", IS.StringControllerType.TYPE_OPEN_DIR)[0]
	var project_res_edit_cont: IS.EditBoxContainer = new_project_res.create_custom_edit("base_informations", new_project_res, [])[0].get_meta(&"owner")
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
	right_vbox_cont.add_child(path_edit.get_parent())
	right_vbox_cont.add_child(project_res_edit_cont)
	right_vbox_cont.add_child(new_btn)
	
	IS.expand(version_rect, true, true)
	IS.expand(bg_rect, true, true)
	IS.expand(left_vsplit_cont)
	IS.expand(right_vbox_cont)
	IS.expand(project_res_edit_cont, true, true)
	
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
		var line_edit: LineEdit = path_edit.get_child(0)
		var dir: String = line_edit.text + "/" + new_project_res.project_name
		ProjectServer2.new_project(new_project_res, dir)
	
	recent_projs_list.item_activated.connect(func(idx: int) -> void:
		if not ProjectServer2.open_project(recent_projs_list.get_item_text(idx)):
			editor_state.recent_projects.erase(recent_projs_list.get_item_text(idx))
			recent_projs_list.remove_item(idx)
			ResourceSaver.save(editor_state, editor_state_path)
			update_popup_menus()
	)
	open_btn.pressed.connect(popup_open_project)
	new_btn.pressed.connect(new_method)




func popup_new_project() -> void:
	var project_res:= ProjectRes.new()
	
	var path_edit: SplitContainer = IS.create_string_edit("project_path", OS.get_system_dir(OS.SYSTEM_DIR_DOCUMENTS), "", IS.StringControllerType.TYPE_OPEN_DIR)[0]
	var project_res_edit_cont: IS.EditBoxContainer = project_res.create_custom_edit("base_informations", project_res, [])[0].get_meta(&"owner")
	
	var accept_method: Callable = func() -> void:
		var line_edit: LineEdit = path_edit.get_child(0)
		var dir: String = line_edit.text + "/" + project_res.project_name
		ProjectServer2.new_project(project_res, dir)
	
	var win_cont: BoxContainer = WindowManager.popup_accept_window(get_window(), Vector2(600., 400.), "New Project", accept_method)
	var win: Window = win_cont.get_window()
	
	win_cont.add_child(path_edit.get_parent())
	win_cont.add_child(project_res_edit_cont)

func popup_open_project(on_project_opened_successfully: Callable = Callable()) -> void:
	
	var file_dialog: FileDialog = WindowManager.create_file_dialog_window(get_window(), FileDialog.FILE_MODE_OPEN_FILE, [], Vector2.ZERO, "Select Project")
	file_dialog.current_dir = OS.get_system_dir(OS.SYSTEM_DIR_DOCUMENTS)
	file_dialog.file_selected.connect(
		func _on_file_dialog_file_selected(path: String) -> void:
			if not path.ends_with(".res"):
				printerr("The file must end with '.res'")
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
		
		var path_edit: Control = IS.create_string_edit(path, new_path, "Choose a New path", 2, MediaServer.ARR_MEDIA_EXTENSIONS[type])[0]
		var edit_box: IS.EditBoxContainer = path_edit.get_parent()
		
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
		
		edit_box.header.add_child(icon_rect)
		edit_box.header.add_child(valid_path_rect)
		edit_box.val_changed.connect(on_update_path_func)
		
		window_cont.add_child(edit_box)
		
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
	
	var settings: AppEditorSettings = EditorServer.editor_settings
	var arr_of_settings: Array[UsableRes] = [settings.edit, settings.performance, settings.shortcuts, settings.theme]
	
	for idx: int in arr_of_settings.size():
		var idx_settings: UsableRes = arr_of_settings[idx]
		if not idx_settings: continue
		
		var sett_split_cont: SplitContainer = IS.create_split_container(2, true)
		var search_line: LineEdit = IS.create_line_edit("Filter Settings", "", IS.TEXTURE_SEARCH)
		var scroll_cont: ScrollContainer = IS.create_scroll_container()
		var idx_settings_edit: IS.EditBoxContainer = UsableRes.create_custom_edit(settings_options[idx].text, idx_settings, [], search_line)[0].get_meta(&"owner")
		
		sett_split_cont.add_child(search_line)
		
		sett_split_cont.add_child(scroll_cont)
		scroll_cont.add_child(idx_settings_edit)
		
		right_margin.add_child(sett_split_cont)
		
		IS.expand(idx_settings_edit, true, true)
	
	left_menu.buttons_container.alignment = BoxContainer.ALIGNMENT_BEGIN
	
	var set_focused_idx: Callable = func(idx: int) -> void:
		for ctrl: Control in right_margin.get_children(): ctrl.hide()
		right_margin.get_child(idx).show()
	
	set_focused_idx.call(0)
	left_menu.focus_index_changed.connect(set_focused_idx)
	
	win_cont.get_window().close_requested.connect(ResourceSaver.save.bind(editor_settings, editor_settings_path))



func popup_save_option_or_save(method: Callable, accept_text: String = "Save & Quit", cancel_text: String = "Don't Save") -> void:
	
	if not ProjectServer2.project_res:
		method.call()
		return
	
	#if not any_change:
		#method.call()
		#return
	
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
	MediaCache.clear_all_videos_cache_frames()
	PlaybackServer.update_videos_clips_ress()


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
			if not ProjectServer2.open_project(popup_menu_recent.get_item_text(id)):
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



func on_window_focus_entered() -> void:
	scan_media_existent()

func on_window_files_dropped(files_pathes: Array[String]) -> void:
	#var mouse_pos: Vector2 = get_viewport().get_mouse_position()
	#var target_layer: Layer = time_line.get_layer_by_pos(mouse_pos)
	#var target_layer_index: int = target_layer.index if target_layer else -1
	#var target_frame_index: int = time_line.get_frame_from_display_pos(mouse_pos.x).keys()[0]
	#
	#var import_func: Callable = func(insert_media: bool = false) -> void:
		#for file_path: String in files_pathes:
			#media_explorer.import_media(file_path, false)
			#if insert_media:
				#ProjectServer.add_imported_clip(
					#MediaServer.get_media_type_from_path(file_path),
					#file_path, target_layer_index, target_frame_index
				#)
	#
	#if media_explorer.get_global_rect().has_point(mouse_pos):
		#import_func.call()
	#elif time_line.get_global_rect().has_point(mouse_pos):
		#import_func.call(true)
	#else:
		#return
	#
	#media_explorer.update()
	#ProjectServer.emit_media_clips_change()
	pass



