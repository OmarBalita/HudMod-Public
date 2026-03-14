class_name CompShake extends ComponentRes

@export var speed: float = 1.
@export var domain: float = 25.
@export var normalized: bool

func _get_exported_props() -> Dictionary[StringName, ExportInfo]:
	return {
		&"speed": export(float_args(speed, .0, INF)),
		&"domain": export(float_args(domain, .0, INF)),
		&"normalized": export(bool_args(normalized))
	}

func _process(frame: int) -> void:
	var noise: FastNoiseLite = GlobalServer.global_usable_res.noise_texture.noise
	
	var x: float = frame * speed
	var position: Vector2 = Vector2(
		noise.get_noise_1d(x),
		noise.get_noise_1d(x + 20.)
	)
	if normalized: position = position.normalized() * domain
	else: position *= domain
	submit_stacked_value(&"position", position)

