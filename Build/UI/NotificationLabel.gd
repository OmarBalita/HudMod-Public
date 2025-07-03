class_name NotificationLabel extends Label


@export_multiline var notification_text: String:
	set(val):
		show_notification_label()
		notification_text = val
		text = val
		notification_time += 1
		var curr_notification = notification_time
		if progress_bar:
			progress_bar.value = progress_bar.max_value
			var tween = create_tween()
			tween.tween_property(
				progress_bar, "value",
				progress_bar.min_value,
				notification_dur
			)
		await get_tree().create_timer(notification_dur).timeout
		if curr_notification != notification_time:
			return
		animation_hide()

@export_group(&"Animation")
@export var notification_dur: float = 3.0
@export var hide_dur: float = .5
@export var progress_bar: ProgressBar

var notification_time: int



func set_notification_text(text: String) -> void:
	notification_text = text

func get_notification_text() -> String:
	return notification_text



func _ready() -> void:
	hide_notification_label()

func animation_hide() -> void:
	var tween = create_tween()
	tween.tween_property(self, "modulate:a", .0, hide_dur)
	tween.play()
	tween.finished.connect(hide_notification_label)

func show_notification_label() -> void:
	modulate.a = 1.0
	show()
	if progress_bar:
		progress_bar.show()

func hide_notification_label() -> void:
	hide()
	if progress_bar:
		progress_bar.hide()
