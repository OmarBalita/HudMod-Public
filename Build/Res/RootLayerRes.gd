class_name RootLayerRes extends LayerRes

@export_group("Audio", "audio")
@export var volume: float
@export var mute: bool

func get_volume() -> float: return volume
func set_volume(new_val: float) -> void: volume = new_val
func get_mute() -> bool: return mute
func set_mute(new_val: bool) -> void: mute = new_val

