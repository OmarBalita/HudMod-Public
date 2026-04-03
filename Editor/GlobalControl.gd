class_name GlobalControl extends ShortcutNode

var editor_header: EditorControl.HeaderPanel

func _init() -> void:
	set_mouse_filter(Control.MOUSE_FILTER_IGNORE)
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)

func _ready() -> void:
	EditorServer.global_controls[get_window()] = self
	register_shortcut_quickly(&"left", frame_jump.bind(-1), [ShortcutNode.new_event_key(Key.KEY_LEFT)])
	register_shortcut_quickly(&"right", frame_jump.bind(1), [ShortcutNode.new_event_key(Key.KEY_RIGHT)])
	register_shortcut_quickly(&"jump_left", frame_jump.bind(-10), [ShortcutNode.new_event_key(Key.KEY_LEFT, false, true)])
	register_shortcut_quickly(&"jump_right", frame_jump.bind(10), [ShortcutNode.new_event_key(Key.KEY_RIGHT, false, true)])
	register_shortcut_quickly(&"spacial_left", frame_spacial.bind(-1), [ShortcutNode.new_event_key(Key.KEY_LEFT, true)])
	register_shortcut_quickly(&"spacial_right", frame_spacial.bind(1), [ShortcutNode.new_event_key(Key.KEY_RIGHT, true)])
	register_shortcut_quickly(&"play", play_and_stop, [ShortcutNode.new_event_key(Key.KEY_SPACE)])
	register_shortcut_quickly(&"save", save, [ShortcutNode.new_event_key(Key.KEY_S, true)])
	register_shortcut_quickly(&"undo", undo, [ShortcutNode.new_event_key(Key.KEY_Z, true)])
	register_shortcut_quickly(&"redo", redo, [ShortcutNode.new_event_key(Key.KEY_Z, true, true)])

func _exit_tree() -> void:
	EditorServer.global_controls.erase(get_window())

func frame_jump(jump: int) -> void:
	PlaybackServer.position += jump
	EditorServer.time_line2.navigate_to_cursor(sign(jump))
	EditorServer.time_line2.update_timeline_view()

func frame_spacial(step: int) -> void:
	PlaybackServer.position = EditorServer.time_line2.get_next_spacial_frame(PlaybackServer.position, step)
	EditorServer.time_line2.navigate_to_cursor(sign(step))
	EditorServer.time_line2.update_timeline_view()

func play_and_stop() -> void:
	if PlaybackServer.is_playing():
		PlaybackServer.stop()
	else:
		PlaybackServer.play()

func save() -> void:
	EditorServer.save()

func undo() -> void:
	pass

func redo() -> void:
	pass



