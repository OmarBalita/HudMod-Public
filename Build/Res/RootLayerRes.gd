class_name RootLayerRes extends LayerRes

signal mute_changed(to: bool)

@export_group("Audio", "audio")
@export var mute: bool:
	set(val):
		mute = val
		AudioServer.set_bus_mute(get_bus_idx(), val)
		mute_changed.emit(val)
@export var volume: float = 1.

var bus_unique_name: StringName

func get_volume() -> float: return volume
func set_volume(new_val: float) -> void: volume = new_val
func get_mute() -> bool: return mute
func set_mute(new_val: bool) -> void: mute = new_val

func get_bus_unique_name() -> StringName: return bus_unique_name
func set_bus_unique_name(new_val: StringName) -> void: bus_unique_name = new_val

func get_bus_idx() -> int: return AudioServer.get_bus_index(bus_unique_name)

func _init() -> void:
	_init_bus()

func _notification(what: int) -> void:
	if what == NOTIFICATION_PREDELETE:
		AudioServer.remove_bus(AudioServer.get_bus_index(bus_unique_name))

func _init_bus() -> void:
	bus_unique_name = &"Layer_%d" % get_instance_id()
	AudioServer.add_bus()
	var curr_idx: int = AudioServer.bus_count - 1
	AudioServer.set_bus_name(curr_idx, bus_unique_name)



