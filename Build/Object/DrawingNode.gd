class_name GDDrawingNode extends Node2D


@export var drawing_res: GDDrawingRes:
	set(val):
		
		if drawing_res:
			drawing_res.res_changed.disconnect(queue_redraw)
			drawing_res.points_changed.disconnect(queue_redraw)
			drawing_res.entities_changed.disconnect(queue_redraw)
		
		if val:
			val.res_changed.connect(queue_redraw)
			val.points_changed.connect(queue_redraw)
			val.entities_changed.connect(queue_redraw)
		
		drawing_res = val



func _init(init_drawing_res: GDDrawingRes = null) -> void:
	drawing_res = init_drawing_res


func _draw() -> void:
	
	if drawing_res:
		
		var points = drawing_res.points
		var points_size = points.size()
		
		if not points_size:
			return
		
		var drawn_entities = drawing_res.drawn_entities
		
		var strength = drawing_res.strength
		var line_color = drawing_res.color_line * strength
		var fill_color = drawing_res.color_fill * strength
		var use_color_range = drawing_res.use_color_range
		var color_range = drawing_res.color_range
		
		var baked_width = drawing_res.baked_width
		
		var antialised = drawing_res.antialised
		
		
		# -------------------- Draw Fill --------------------
		if drawing_res.draw_fill:
			draw_polygon_safe(PackedVector2Array(points), fill_color)
		
		# -------------------- Draw Line --------------------
		
		var dist_left: float
		
		if not drawing_res.draw_line:
			return
		
		for time in points_size:
			
			if time < points_size - 1:
				var p1 = points[time]
				var p2 = points[time + 1]
				var curr_baked_width = baked_width[time]
				
				var ratio = float(time) / points_size
				
				var a_to_b_dist = p1.distance_to(p2)
				
				var curr_line_color: Color = line_color
				if use_color_range: curr_line_color *= color_range.sample(ratio)
				
				for e: DrawnEntityRes in drawn_entities:
					
					var type = e.type
					var dist_mode = e.distance_mode
					var dist = e.distance
					var from = e.from
					var to = e.to
					
					var draw_times: int = 1
					
					if dist_mode == 1:
						var full_times = a_to_b_dist + dist_left
						draw_times = floor(full_times / dist)
						var new_dist_left = fmod(full_times, dist * draw_times)
						if is_nan(new_dist_left):
							new_dist_left = a_to_b_dist
						if draw_times > 0:
							dist_left = new_dist_left
						else:
							dist_left += new_dist_left
					else:
						if not time % dist == 0:
							continue
					
					if ratio < from or ratio > to:
						continue
					
					var offset = e.offset
					
					var draw_color = e.custom_color
					var draw_width = e.custom_width
					var draw_antialised = e.custom_antialized
					
					if not e.use_custom:
						draw_color = curr_line_color
						draw_width = curr_baked_width
						draw_antialised = antialised
					
					p1 += offset
					p2 += offset
					
					for draw_time in draw_times:
						
						var time_draw_offset = draw_time * dist / a_to_b_dist
						var point = p1 + (p2 - p1) * time_draw_offset
						
						match type:
							0:
								draw_line(p1, p2, draw_color, draw_width, draw_antialised)
							1:
								draw_dashed_line(p1, p2, draw_color, draw_width, e.dash_scale, true, draw_antialised)
							2:
								var size_result = e.rect_size * draw_width
								draw_rect(Rect2(point - size_result / 2.0, size_result), draw_color, e.filled, -1 if e.filled else e.width_scale, draw_antialised)
							3:
								draw_circle(point, draw_width / 2.0, draw_color, e.filled, -1 if e.filled else e.width_scale, draw_antialised)
							4:
								draw_arc(point, draw_width / 2.0, e.arc_start_angle, e.arc_end_angle, e.arc_points_count, draw_color, e.width_scale, draw_antialised)
							5:
								if e.texture: draw_mesh(e.mesh, e.texture.get_texture(), Transform2D(e.rotation, e.scale * draw_width, e.skew, point), draw_color)
							6:
								if e.texture: draw_texture(e.texture.get_texture(), point, draw_color)
		
		# -------------------- Draw Caps --------------------
		
		if baked_width.size():
			var begin_width = drawing_res.cap_begin_scale * baked_width.front()
			var end_width = drawing_res.cap_end_scale * baked_width.back()
			var front_point = points[0]
			var back_point = points[-1]
			
			match drawing_res.cap_begin_type:
				2: draw_circle(front_point, begin_width, line_color, true, -1.0, true)
			
			match drawing_res.cap_end_type:
				2: draw_circle(back_point, end_width, line_color, true, -1.0, true)


func draw_polygon_safe(points: PackedVector2Array, color: Color):
	
	if points.size() < 3:
		return
	
	var triangles = Geometry2D.triangulate_polygon(points)
	
	if triangles.size():
		draw_polygon(points, PackedColorArray([color]))
	else:
		draw_polyline(points, color)


func get_drawing_res() -> GDDrawingRes:
	return drawing_res

func set_drawing_res(new_drawing_res: GDDrawingRes) -> void:
	drawing_res = new_drawing_res





