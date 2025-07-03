class_name MediaClip extends ColorRect

@export var clip_res: MediaClipRes

func _ready() -> void:
	InterfaceServer.set_base_settings(self)
