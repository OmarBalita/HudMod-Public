class_name MediaClip extends ColorRect


func _ready() -> void:
	InterfaceServer.set_base_settings(self)
	clip_contents = true

