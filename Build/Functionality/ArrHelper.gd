class_name ArrHelper extends Object

static func insert_packed_vec2_array(arr_a: PackedVector2Array, idx: int, arr_b: PackedVector2Array) -> PackedVector2Array:
	if idx < 0 or idx > arr_a.size():
		return arr_a
	var left: PackedVector2Array = arr_a.slice(0, idx)
	var right: PackedVector2Array = arr_a.slice(idx)
	
	return left + arr_b + right

static func get_reordered_vec2_array(arr: PackedVector2Array, start_idx: int) -> PackedVector2Array:
	return arr.slice(start_idx) + arr.slice(0, start_idx)
