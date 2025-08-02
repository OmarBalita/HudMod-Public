class_name GDDrawingNode extends Node2D


@export var drawing_res: GDDrawingRes


func _ready() -> void:
	drawing_res.points_changed.connect(queue_redraw)
	drawing_res.entities_changed.connect(queue_redraw)

func _draw() -> void:
	
	if drawing_res:
		
		var points = drawing_res.points
		var points_size = points.size()
		
		if not points_size:
			return
		
		var drawn_entities = drawing_res.drawn_entities
		
		var line_color = drawing_res.color_line
		var fill_color = drawing_res.color_fill
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
				
				if color_range:
					line_color = color_range.sample(ratio)
				
				for drawn_entity in drawn_entities:
					
					var type = drawn_entity.keys()[0]
					var info = drawn_entity.values()[0]
					var dist = info.dist
					var range = info.range
					var dist_mode = info.dist_mode
					
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
					
					if ratio < range[0] or ratio > range[1]:
						continue
					
					var offset = info.offset
					var draw_color = info.custom_color
					var draw_width = info.custom_width
					var draw_antialised = info.custom_antialiased
					
					if draw_color == null:
						draw_color = line_color
					if draw_width == null:
						draw_width = curr_baked_width
					if draw_antialised == null:
						draw_antialised = antialised
					
					p1 += offset
					p2 += offset
					
					
					for draw_time in draw_times:
						
						var time_draw_offset = draw_time * dist / a_to_b_dist
						var point = p1 + (p2 - p1) * time_draw_offset
						
						match type:
							"line":
								draw_line(p1, p2, draw_color, draw_width, draw_antialised)
							"dashed_line":
								draw_dashed_line(p1, p2, draw_color, draw_width, info.dash, true, draw_antialised)
							"rect":
								var size_result = info.rect_size * draw_width
								draw_rect(Rect2(point - size_result / 2.0, size_result), draw_color, info.filled, info.width_scale, draw_antialised)
							"circle":
								draw_circle(point, draw_width / 2.0, draw_color, info.filled, info.width_scale, draw_antialised)
							"arc":
								draw_arc(point, draw_width / 2.0, info.start_angle, info.end_angle, info.points_count, draw_color, info.width_scale, draw_antialised)
							"mesh":
								draw_mesh(info.mesh, info.texture, Transform2D(info.rotation, info.scale * draw_width, info.skew, point), draw_color)
							"texture":
								draw_texture(info.texture, point, draw_color)
		
		# -------------------- Draw Caps --------------------
		
		if baked_width.size():
			var begin_width = drawing_res.cap_begin_scale * baked_width.front()
			var end_width = drawing_res.cap_end_scale * baked_width.back()
			var front_point = points.front()
			var back_point = points.back()
			
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








