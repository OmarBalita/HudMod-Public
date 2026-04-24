class_name ColorCorrectionEditor extends EditorControl

func _ready_editor() -> void:
	super()
	body.add_child(IS.create_label("Color correction editor, coming soon"))
