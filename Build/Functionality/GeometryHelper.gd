class_name GeometryHelper extends Object

static func find_closest_two_points(polygon_a: PackedVector2Array, polygon_b: PackedVector2Array) -> Vector2i:
	var result: Vector2i
	var min_dist: float = INF
	
	for ia: int in polygon_a.size():
		var pa: Vector2 = polygon_a[ia]
		for ib: int in polygon_b.size():
			var pb: Vector2 = polygon_b[ib]
			var dist: float = pa.distance_to(pb)
			if dist < min_dist:
				result = Vector2i(ia, ib)
				min_dist = dist
	
	return result
