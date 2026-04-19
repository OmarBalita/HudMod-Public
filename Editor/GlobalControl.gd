class_name GlobalControl extends ShortcutNode

var editor_header: EditorControl.HeaderPanel

func _init() -> void:
	set_mouse_filter(Control.MOUSE_FILTER_IGNORE)
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)

func _ready() -> void:
	EditorServer.global_controls[get_window()] = self
	
	key = &"Global"
	load_shortcuts_from_settings()

func _exit_tree() -> void:
	EditorServer.global_controls.erase(get_window())

func frame_jump(jump: int) -> void:
	if Renderer.is_working: return
	PlaybackServer.position += jump
	EditorServer.time_line2.navigate_to_cursor(sign(jump))
	EditorServer.time_line2.update_timeline_view()

func frame_spacial(step: int) -> void:
	if Renderer.is_working: return
	PlaybackServer.position = EditorServer.time_line2.get_next_spacial_frame(PlaybackServer.position, step)
	EditorServer.time_line2.navigate_to_cursor(sign(step))
	EditorServer.time_line2.update_timeline_view()

func play_and_stop() -> void:
	if Renderer.is_working: return
	if PlaybackServer.is_playing():
		PlaybackServer.stop()
	else:
		PlaybackServer.play()

func new() -> void: EditorServer.popup_new_project()
func open() -> void: EditorServer.popup_open_project()
func save() -> void: ProjectServer2.save()
func save_as() -> void: EditorServer.popup_save_as()
func undo() -> void: ProjectServer2.undo()
func redo() -> void: ProjectServer2.redo()
func exit() -> void: EditorServer.popup_save_option_or_save(get_tree().quit)
func toggle_fullscreen() -> void: EditorServer.toggle_fullscreen()
func report_bugs() -> void: pass





