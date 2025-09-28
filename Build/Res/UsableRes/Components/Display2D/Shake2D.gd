class_name Shake2DComponent extends ComponentRes

func _init() -> void:
	set_res_id("Shake2D")
	register_properties({
		dur_between_peaks = 1,
		offset_scale = 5.0,
		direction = Vector2.RIGHT,
		spread = 1.0,
		normalized = false,
		interpolate = true,
	})

func _get_exported_parameters() -> Dictionary[StringName, Dictionary]:
	var frame: int = EditorServer.frame
	return {
		dur_between_peaks = CtrlrHelper.get_float_controller_args([], true, get_prop(&"dur_between_peaks", frame), 1, 1e6),
		offset_scale = CtrlrHelper.get_float_controller_args([], false, get_prop(&"offset_scale", frame), .0, INF, .001, .5),
		direction = CtrlrHelper.get_vec2_controller_args([], get_prop(&"direction", frame)),
		spread = CtrlrHelper.get_float_controller_args([], false, get_prop(&"spread", frame), .0, 1.0),
		normalized = CtrlrHelper.get_bool_controller_args([], get_prop(&"normalized", frame)),
		interpolate = CtrlrHelper.get_bool_controller_args([], get_prop(&"interpolate", frame))
	}

func _process(node: Node, frame: int) -> void:
	var x_curve: Curve = get_prop(&"x_curve")
	var y_curve: Curve = get_prop(&"y_curve")
	var frame_pos: Vector2 = Vector2(x_curve.sample(frame), y_curve.sample(frame))
	if get_prop(&"interpolate", frame):
		node.position = frame_pos
	elif (get_prop(&"points")).has(frame):
		node.position = frame_pos

func _update() -> void:
	if not owner:
		return
	
	var x_baked_curve: Curve = Curve.new()
	var y_baked_curve: Curve = Curve.new()
	var points: Dictionary[int, Vector2]
	
	# Get Offset Scale
	var offset_scale: float = get_prop(&"offset_scale")
	
	# Get Peaks Times
	var length: float = owner.length
	var dur_between_peaks: float = get_prop(&"dur_between_peaks")
	var peaks_times: int = int(length / dur_between_peaks)
	x_baked_curve.max_domain = length
	x_baked_curve.min_value = -offset_scale
	x_baked_curve.max_value = offset_scale
	y_baked_curve.max_domain = length
	y_baked_curve.min_value = -offset_scale
	y_baked_curve.max_value = offset_scale
	#ObjectServer.describe(x_baked_curve, {max_domain = length, min_val = -offset_scale, max_val = offset_scale})
	#ObjectServer.describe(y_baked_curve, {max_domain = length, min_val = -offset_scale, max_val = offset_scale})
	
	# Loop and Collect Peaks
	var add_peak_point_func: Callable = func(frame: int) -> void:
		var dir: Vector2 = get_prop(&"direction")
		var spread: float = get_prop(&"spread")
		var spread_dir: Vector2 = Vector2(randf_range(-spread, spread), randf_range(-spread, spread))
		var rand_dir: Vector2 = dir * Vector2(randf(), randf()).normalized()
		var result_pos: Vector2 = ((rand_dir - rand_dir * spread) + spread_dir)
		if get_prop(&"normalized"):
			result_pos = result_pos.normalized()
		result_pos *= offset_scale
		x_baked_curve.add_point(Vector2(frame, result_pos.x))
		y_baked_curve.add_point(Vector2(frame, result_pos.y))
		points[frame] = result_pos
	
	var latest_frame: int
	add_peak_point_func.call(0)
	for time: int in peaks_times + 2:
		var frame: int = time * dur_between_peaks
		if frame == latest_frame: continue
		add_peak_point_func.call(frame)
	
	register_property(&"x_curve", x_baked_curve)
	register_property(&"y_curve", y_baked_curve)
	register_property(&"points", points)








