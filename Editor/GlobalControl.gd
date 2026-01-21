class_name GlobalControl extends ShortcutNode

var editor_header: EditorControl.HeaderPanel

func _init() -> void:
	set_mouse_filter(Control.MOUSE_FILTER_IGNORE)
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)

func _ready() -> void:
	EditorServer.global_controls[get_window()] = self
	register_shortcut_quickly(&"play", play, [ShortcutNode.new_event_key(Key.KEY_SPACE)])
	register_shortcut_quickly(&"save", save, [ShortcutNode.new_event_key(Key.KEY_S, true)])
	register_shortcut_quickly(&"undo", undo, [ShortcutNode.new_event_key(Key.KEY_Z, true)])
	register_shortcut_quickly(&"redo", redo, [ShortcutNode.new_event_key(Key.KEY_Z, true, true)])

func _exit_tree() -> void:
	EditorServer.global_controls.erase(get_window())

func play() -> void:
	#var timeline: TimeLine = EditorServer.time_line
	#if timeline.is_playing:
		#timeline.stop()
	#else:
		#timeline.play()
	pass

func save() -> void:
	ProjectServer.save_project()
	GlobalServer.save_global()
	MediaServer.save_not_saved_yet()
	MediaServer.delete_not_deleted_yet()

func undo() -> void:
	pass

func redo() -> void:
	pass



