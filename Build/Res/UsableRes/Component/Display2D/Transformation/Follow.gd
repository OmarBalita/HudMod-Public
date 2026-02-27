class_name CompFollow extends ComponentRes

@export var target:= MediaClipResPath.new_mediares_path(MediaClipResPath.node2d_cond):
	set(val):
		val.cond_func = target.cond_func
		if val: val.res_changed.connect(emit_res_changed)
		if target: target.res_changed.disconnect(emit_res_changed)
		target = val
@export_group("Enabling", "enable")
@export var enable_pos: bool = true
@export var enable_rot: bool = false
@export var enable_scale: bool = false
@export_group("Weight", "weight")
@export var weight_pos: int = 10
@export var weight_rot: int = 10
@export var weight_scale: int = 10

func _init() -> void:
	method_type = MethodType.SET

func _get_exported_props() -> Dictionary[StringName, ExportInfo]:
	return {
		&"target": export([target]),
		
		&"Enabling": export_method(ExportMethodType.METHOD_ENTER_CATEGORY),
		&"enable_pos": export(bool_args(enable_pos)),
		&"enable_rot": export(bool_args(enable_rot)),
		&"enable_scale": export(bool_args(enable_scale)),
		&"_Enabling": export_method(ExportMethodType.METHOD_EXIT_CATEGORY),
		
		&"Weight": export_method(ExportMethodType.METHOD_ENTER_CATEGORY),
		&"weight_pos": export(int_args(weight_pos, 1, 1000)),
		&"weight_rot": export(int_args(weight_rot, 1, 1000)),
		&"weight_scale": export(int_args(weight_scale, 1, 1000)),
		&"_Weight": export_method(ExportMethodType.METHOD_EXIT_CATEGORY)
	}

func _process(frame: int) -> void:
	
	if target.is_valid():
		
		var target_res: MediaClipRes = target.get_media_res()
		
		var global_frame: int = frame + owner.clip_pos
		var target_frame: int = global_frame - target_res.clip_pos
		
		var precalculated_stacked: Dictionary[int, Array] # Array has 2 elements, first: stacked_values, other: weight at time as precalculated.
		
		for time: int in max(weight_pos, weight_rot, weight_scale):
			var curr_frame: int = clamp(target_frame - time, 0, target_res.length)
			precalculated_stacked[time] = [target_res.shared_data_get_stacked_at(curr_frame), pow(1., time)]
		
		if enable_pos:
			var weight_sum: Vector2
			var total_weight: float
			for time: int in weight_pos:
				var at: Array = precalculated_stacked[time]
				var target_pos: Vector2 = target_res.get_custom_stacked_values_key_result(at[0], &"position")
				var weight: int = at[1]
				weight_sum += target_pos * weight
				total_weight += weight
			submit_stacked_value(&"position", weight_sum / total_weight)
		
		if enable_rot:
			var weight_sum: float
			var total_weight: float
			for time: int in weight_rot:
				var at: Array = precalculated_stacked[time]
				var target_rot: float = target_res.get_custom_stacked_values_key_result(at[0], &"rotation_degrees")
				var weight: int = at[1]
				weight_sum += target_rot * weight
				total_weight += weight
			submit_stacked_value(&"rotation_degrees", weight_sum / total_weight)
		
		if enable_scale:
			var weight_sum: Vector2
			var total_weight: float
			for time: int in weight_scale:
				var at: Array = precalculated_stacked[time]
				var total_scale: Vector2 = target_res.get_custom_stacked_values_key_result(at[0], &"scale")
				var weight: int = at[1]
				weight_sum += total_scale * weight
				total_weight += weight
			submit_stacked_value(&"scale", weight_sum / total_weight)


