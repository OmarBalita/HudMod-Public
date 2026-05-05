#############################################################################
##  This file is part of: HudMod Video Editor                              ##
##  https://omar-top.itch.io/hudmod-video-editor                           ##
## ----------------------------------------------------------------------- ##
##  Copyright © 2026 Omar Mohammed Balita.                                 ##
## ----------------------------------------------------------------------- ##
##  This program is free software: you can redistribute it and/or modify   ##
##  it under the terms of the GNU General Public License as published by   ##
##  the Free Software Foundation, either version 3 of the License, or      ##
##  (at your option) any later version.                                    ##
##                                                                         ##
##  This program is distributed in the hope that it will be useful,        ##
##  but WITHOUT ANY WARRANTY; without even the implied warranty of         ##
##  MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the           ##
##  GNU General Public License for more details.                           ##
##                                                                         ##
##  You should have received a copy of the GNU General Public License      ##
##  along with this program. If not, see <https://www.gnu.org/licenses/>.  ##
#############################################################################
# Old code that has been discontinued
class_name GDDraw extends Node2D

@export var drawings_ress: Array[GDDrawingRes]
var curr_drawing_res: GDDrawingRes


func get_drawings_ress() -> Array[GDDrawingRes]:
	return drawings_ress

func set_drawings_ress(new_drawings_ress: Array[GDDrawingRes]) -> void:
	drawings_ress = new_drawings_ress

func start_new_drawing(default_drawing_res: GDDrawingRes, start_point: Vector2) -> GDDrawingRes:
	var drawing_res = setup_drawing_res(default_drawing_res)
	drawing_res.add_point(start_point)
	
	drawings_ress.append(drawing_res)
	curr_drawing_res = drawing_res
	
	update_drawings()
	
	return drawing_res

func create_new_drawing(default_drawing_res: GDDrawingRes, points: PackedVector2Array, index: int = -1, entity_line: bool = false, update_points: bool = true, emit_changes: bool = true) -> GDDrawingRes:
	var drawing_res = setup_drawing_res(default_drawing_res, entity_line)
	
	if update_points:
		drawing_res.set_points(points)
	
	if index == -1:
		index = drawings_ress.size()
	drawings_ress.insert(index, drawing_res)
	
	if emit_changes:
		update_drawings()
	
	return drawing_res

func setup_drawing_res(drawing_res: GDDrawingRes, entity_line: bool = false) -> GDDrawingRes:
	drawing_res = drawing_res.duplicate(true)
	drawing_res.set_is_brush(false)
	
	var drawn_entities: Array[DrawnEntityRes]
	for drawn_entity: DrawnEntityRes in drawing_res.get_drawn_entities():
		drawn_entities.append(drawn_entity.duplicate(true))
	drawing_res.set_drawn_entities(drawn_entities)
	
	if entity_line: drawing_res.entity()
	
	drawing_res.sliced.connect(
		func(right_slice_points: PackedVector2Array):
			create_new_drawing(drawing_res, right_slice_points)
	)
	return drawing_res

func remove_drawing(drawing_res: GDDrawingRes, emit_changes: bool = true) -> int:
	var index = drawings_ress.find(drawing_res)
	drawings_ress.erase(drawing_res)
	if emit_changes:
		update_drawings()
	return index

func add_point_to_current_drawing(new_point: Vector2) -> void:
	curr_drawing_res.add_point(new_point)

func set_points_to_current_drawing(new_points: PackedVector2Array) -> void:
	curr_drawing_res.set_points(new_points)

func erase_drawing_nodes(cond_func: Callable) -> void:
	for drawing_res in drawings_ress:
		drawing_res.erase(cond_func)




var drawings_subdv_points: Dictionary[Vector2, Array]

func fill_drawing_nodes(default_drawing_res: GDDrawingRes, pos: Vector2i, grid_size: int = 2) -> void:
	
	bake_drawing_subdv_points(grid_size)
	
	var fill_points = get_fill_from_pos_bfs(grid_size, get_window().get_size(), pos)
	var coordinate_polygon_points = trace_polygon(fill_points)
	var result_polygon_points: PackedVector2Array
	for point in coordinate_polygon_points:
		result_polygon_points.append(Vector2(point * grid_size) + Vector2(grid_size, grid_size) / 2.0)
	
	var fill_drawing = create_new_drawing(default_drawing_res, result_polygon_points, 0)
	fill_drawing.draw_line = false
	fill_drawing.draw_fill = true
	
	update_drawings()


func bake_drawing_subdv_points(grid_size: int) -> void:
	
	var grid_size_v2 = Vector2(grid_size, grid_size) * 2
	
	drawings_subdv_points.clear()
	
	for drawing_res in drawings_ress:
		
		var points = drawing_res.points
		
		for index: int in range(points.size()):
			
			var p1 = points[index]
			
			add_point_to_drawing_subdv_points(p1, grid_size_v2)
			
			if index < points.size() - 1:
				
				var p2 = points[index + 1]
				var a_to_b_dist = p1.distance_to(p2)
				
				if a_to_b_dist >= grid_size:
					var offset_times = ceil(a_to_b_dist / grid_size)
					for offset_time in offset_times:
						var offset = offset_time * grid_size / a_to_b_dist
						var point = p1 + (p2 - p1) * offset
						add_point_to_drawing_subdv_points(point, grid_size_v2)




func add_point_to_drawing_subdv_points(point: Vector2, grid_size: Vector2) -> void:
	var group = snapped(point, grid_size)
	if not drawings_subdv_points.has(group):
		drawings_subdv_points[group] = []
	drawings_subdv_points[group].append(point)



# Made By Claude-AI، بتصرف

const DIRECTIONS = [
	Vector2i.UP,
	Vector2i.DOWN,
	Vector2i.RIGHT,
	Vector2i.LEFT
]

var directions:= [
	Vector2(-1, -1), Vector2(0, -1), Vector2(1, -1),
	Vector2(1, 0), Vector2(1, 1), Vector2(0, 1),
	Vector2(-1, 1), Vector2(-1, 0)
]


func get_fill_from_pos_bfs(grid_size: int, grid_rect_size: Vector2i, start_pos: Vector2i, filled_positions: Array = [], max_iterations: int = 100000) -> Array:
	grid_rect_size /= grid_size
	start_pos /= grid_size
	
	# تحديد حدود الشبكة
	var grid_bounds:= Rect2i(Vector2.ZERO, grid_rect_size)
	
	# مصفوفة لتتبع الخلايا المزارة
	var visited:= {}
	
	# قائمة انتظار للخلايا المراد فحصها (FIFO للـ BFS)
	var queue:= [start_pos]
	var result:= []
	
	# تحديد اللون/النوع الأصلي للبكسل المراد ملؤه
	
	while queue.size() > 0 and result.size() < max_iterations:
		# أخذ أول عنصر من القائمة (FIFO)
		var curr_pos = queue.pop_front()
		
		# تحقق من صحة الموقع
		if not grid_bounds.has_point(curr_pos):
			continue
		
		# تحقق من أن الخلية لم تُزار من قبل
		var pos_key = str(curr_pos.x) + "," + str(curr_pos.y)
		if pos_key in visited:
			continue
		
		if is_rect_has_any_point(Rect2(curr_pos * grid_size, Vector2(grid_size, grid_size))):
			result.append(curr_pos)
			continue
		
		# إضافة الموقع للنتيجة وتسجيله كمُزار
		visited[pos_key] = true
		#result.append(curr_pos)
		
		# إضافة الخلايا المجاورة لنهاية القائمة (الاتجاهات الأربع)
		for direction in DIRECTIONS:
			var next_pos = curr_pos + direction
			queue.push_back(next_pos)  # يُضاف في النهاية
	
	return result

func is_rect_has_any_point(rect: Rect2) -> bool:
	var check_group = snapped(rect.position, rect.size * 2)
	if drawings_subdv_points.has(check_group):
		for point in drawings_subdv_points.get(check_group):
			if rect.has_point(point):
				return true
	return false

# ChatGPT Trace Function
func trace_polygon(points: Array) -> Array:
	var pixel_set:= pixels_to_set(points)
	var polygon:= []
	var start = find_top_left_pixel(pixel_set)
	var current: Vector2 = start
	var prev_dir:= Vector2(-1, 0) # نبدأ من اليسار
	
	while true:
		polygon.append(current)
		var found := false
		for i in range(8):
			var dir_idx = (directions.find(prev_dir) + i) % 8
			var next_pos = current + directions[dir_idx]
			if next_pos in pixel_set:
				current = next_pos
				prev_dir = directions[(dir_idx + 5) % 8] # يدور قليلاً عكس عقارب الساعة
				found = true
				break
		if not found or current == start:
			break
	
	return Array(polygon)

# Made by ChatGPT
func pixels_to_set(pixels: Array) -> Dictionary:
	var s:= {}
	for p in pixels:
		s[Vector2(int(p.x), int(p.y))] = true
	return s

# Made by ChatGPT
func find_top_left_pixel(s: Dictionary) -> Vector2:
	var top_left = null
	for p in s.keys():
		if top_left == null or p.y < top_left.y or (p.y == top_left.y and p.x < top_left.x):
			top_left = p
	return top_left

# My Own Trace Function
func trace_polygon_from_points(points: Array) -> Array:
	
	var start_point = points[0]
	var latest_point = start_point
	
	var result: Array = [start_point]
	
	while true:
		
		var old_point = latest_point
		
		for dir in directions:
			var new_point = latest_point + dir
			if not points.has(new_point):
				continue
			if result.has(new_point):
				continue
			latest_point = new_point
			result.append(new_point)
			break
		
		if old_point == latest_point:
			break
	
	return result





func update_drawings() -> void:
	
	for child: Node in get_children():
		if child is GDDrawingNode:
			var drawing_res = child.drawing_res
			if drawing_res.points.size() == 0:
				drawings_ress.erase(drawing_res)
			child.queue_free()
	
	for drawing_res: GDDrawingRes in drawings_ress:
		var drawing_node = GDDrawingNode.new()
		drawing_node.drawing_res = drawing_res
		add_child(drawing_node)



func loop_drawings_ress(custom_info: Dictionary, function: Callable) -> Dictionary: # the Function has One Argument (drawing_res as GDDrawingRes)
	custom_info.merge({"break": false})
	for drawing_res: GDDrawingRes in drawings_ress:
		if custom_info.break:
			break
		function.call(drawing_res, custom_info)
	return custom_info

func loop_all_points(custom_info: Dictionary, function: Callable, drawings_ress: Array = drawings_ress) -> Dictionary: # the Function has Two Arguments (drawing_res: GDDrawingRes, point_index: int, point: Vector2)
	custom_info.merge({"break": false})
	for drawing_res: GDDrawingRes in drawings_ress:
		var points = drawing_res.points
		for point_index: int in points.size():
			if custom_info.break == true:
				break
			var point = points[point_index]
			function.call(drawing_res, point_index, point, custom_info)
	return custom_info

func get_drawings_points_size() -> int:
	var info = loop_drawings_ress({"points_size": 0},
		func(drawing_res: GDDrawingRes, info: Dictionary) -> void:
			info.points_size += drawing_res.points.size()
	)
	return info.get("points_size")










