class_name CompTextGenShape extends Text2DComponentRes

@export var subdivision: int = 1

@export var debug: bool = true
@export var debug_color: Color = Color.LIME_GREEN

@export var result: Dictionary[int, Array]

func get_result() -> Dictionary[int, Array]: return result
func set_result(new_val: Dictionary[int, Array]) -> void: result = new_val

func _get_exported_props() -> Dictionary[StringName, ExportInfo]:
	return {
		&"Generate": export_method(ExportMethodType.METHOD_CALLABLE, method_callable_args(_on_generate_button_pressed, Color.DIM_GRAY)),
		&"subdivision": export(int_args(subdivision, 0, 6)),
		&"Debug": export_method(ExportMethodType.METHOD_ENTER_CATEGORY),
		&"debug": export(bool_args(debug)),
		&"debug_color": export(color_args(debug_color)),
		&"_Debug": export_method(ExportMethodType.METHOD_EXIT_CATEGORY),
	}

func _process(frame: int) -> void:
	
	if result.is_empty() or not debug:
		return
	
	var colors:= PackedColorArray([debug_color])
	for global_idx: int in result:
		var paths: Array = result[global_idx]
		for idx: int in paths.size():
			var path: PackedVector2Array = paths[idx]
			submit_polygon_postdraw(path, colors)

func _on_generate_button_pressed(usable_ress: Array[UsableRes]) -> void:
	for res: CompTextGenShape in usable_ress:
		res.generate_shape()


func generate_shape() -> void:
	result.clear()
	
	var lines_data: Array[Text2DClipRes.LineData] = owner.lines_data
	
	var global_idx: int
	
	for line_data: Text2DClipRes.LineData in lines_data:
		
		var glyphs: Array[Dictionary] = line_data.glyphs
		var chars: Array[CharFXTransform] = line_data.chars
		
		for glyph_idx: int in glyphs.size():
			
			var glyph: Dictionary = glyphs[glyph_idx]
			var char: CharFXTransform = chars[glyph_idx]
			var offset: Vector2 = char.offset
			
			var glyph_contours: Dictionary = font_get_glyph_contours_with_smooth_paths(glyph.font_rid, owner.font_size, glyph.index, subdivision)
			var points: PackedVector3Array = glyph_contours.points
			var contours: Array = glyph_contours.contours
			var paths: Array[PackedVector2Array] = glyph_contours.smooth_paths
			
			for path: PackedVector2Array in paths:
				for path_idx: int in path.size():
					path[path_idx] += offset
			
			result[global_idx] = []
			
			#var start_idx: int
			#for end_idx: int in contours:
				#
				#var path: PackedVector2Array
				#for i: int in range(start_idx, end_idx + 1):
					#var point: Vector3 = points[i]
					#path.append(offset + Vector2(point.x, point.y))
				#
				#paths.append(path)
				#start_idx = end_idx + 1
			#
			
			if paths.is_empty():
				continue
			
			var master_path: PackedVector2Array = paths[0]
			
			for path_idx: int in range(1, paths.size()):
				var curr_path: PackedVector2Array = paths[path_idx]
				var is_master_intersect_with: bool
				for point: Vector2 in curr_path:
					if Geometry2D.is_point_in_polygon(point, master_path):
						is_master_intersect_with = true
						break
				if is_master_intersect_with:
					var closest_points: Vector2i = GeometryHelper.find_closest_two_points(master_path, curr_path)
					curr_path = ArrHelper.get_reordered_vec2_array(curr_path, closest_points.y)
					master_path = ArrHelper.insert_packed_vec2_array(master_path, closest_points.x, curr_path)
				else:
					result[global_idx].append(curr_path)
			
			result[global_idx].append(master_path)
			
			global_idx += 1
	
	emit_res_changed()

# Written by Gemini
static func font_get_glyph_contours_with_smooth_paths(font_rid: RID, size: int, glyph_index: int, subdivision: int) -> Dictionary:
	var glyph_data: Dictionary = Text2DClipRes.ts.font_get_glyph_contours(font_rid, size, glyph_index)
	
	var points: PackedVector3Array = glyph_data.points
	var contours: PackedInt32Array = glyph_data.contours
	
	var smooth_paths: Array[PackedVector2Array] = []
	var start_idx: int = 0
	
	var curve: Curve2D = Curve2D.new()
	
	for end_idx: int in contours:
		curve.clear_points()
		
		var count: int = end_idx - start_idx + 1
		
		for i: int in range(count):
			var curr_idx: int = start_idx + i
			var next_idx: int = start_idx + (i + 1) % count
			
			var curr_v3: Vector3 = points[curr_idx]
			var next_v3: Vector3 = points[next_idx]
			
			var curr_p: Vector2 = Vector2(curr_v3.x, curr_v3.y)
			var next_p: Vector2 = Vector2(next_v3.x, next_v3.y)
			
			var curr_on: bool = is_equal_approx(curr_v3.z, 1.)
			var next_on: bool = is_equal_approx(next_v3.z, 1.)
			
			if curr_on:
				if next_on:
					curve.add_point(curr_p)
				else:
					var ctrl_p: Vector2 = next_p
					var target_idx: int = start_idx + (i + 2) % count
					var target_v3: Vector3 = points[target_idx]
					var target_p: Vector2 = Vector2(target_v3.x, target_v3.y)
					var target_on: bool = is_equal_approx(target_v3.z, 1.)
					
					if not target_on:
						target_p = (ctrl_p + target_p) / 2.
						
					curve.add_point(curr_p, Vector2.ZERO, ctrl_p - curr_p)
			
			elif not curr_on and not next_on:
				var mid_p: Vector2 = (curr_p + next_p) / 2.
				curve.add_point(mid_p)
		
		smooth_paths.append(curve.tessellate(subdivision, .5))
		start_idx = end_idx + 1
	
	return {
		&"points": points,
		&"contours": contours,
		&"orientation": glyph_data.orientation,
		&"smooth_paths": smooth_paths
	}



