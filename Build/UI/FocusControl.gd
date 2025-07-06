class_name FocusControl extends Control

@export_multiline() var editor_guides: Array[Dictionary]

var is_focus: bool:
	set(val):
		is_focus = val
		var tween = create_tween()
		tween.tween_property(self, "focus_alpha", float(is_focus), .15)
		if is_focus:
			EditorServer.push_guides(editor_guides)

var focus_alpha: float = .0:
	set(val):
		focus_alpha = val
		queue_redraw()


func set_is_focus(focus: bool) -> void:
	is_focus = focus

func _ready() -> void:
	mouse_entered.connect(set_is_focus.bind(true))
	mouse_exited.connect(set_is_focus.bind(false))


func _draw() -> void:
	draw_rect(
		Rect2(Vector2.ZERO + Vector2.ONE, size - Vector2(2, 2)),
		Color(InterfaceServer.STYLE_ACCENT.bg_color, focus_alpha),
		false, 2.0
	)















