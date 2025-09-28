class_name PopupedText extends PopupedControl

@export var text: String:
	set(val):
		text = val
		if not text_label.is_node_ready():
			await text_label.ready
		text_label.text = text

var text_label: Label = IS.create_label(text)

func set_text(_text: String) -> void:
	text = _text

func get_text() -> String:
	return text

func _init() -> void:
	popdown_when_mouse_move = true

func _ready() -> void:
	super()
	IS.expand(text_label)
	add_child(text_label)















