class_name ArrHelper extends Object

static func int32_array_find_closest(num: int, sorted_arr: PackedInt32Array) -> int:
	
	var n: int = sorted_arr.size()
	if n == 0: return -1
	elif num <= sorted_arr[0]: return 0
	elif num >= sorted_arr[n - 1]: return n - 1
	
	var leftright: Vector2i = int32_array_find_leftright(num, sorted_arr)
	
	if abs(sorted_arr[leftright.x] - num) < abs(sorted_arr[leftright.y] - num): return leftright.x
	else: return leftright.y

static func int32_array_find_leftright(num: int, sorted_arr: PackedInt32Array) -> Vector2i:
	
	var left: int = 0
	var right: int = sorted_arr.size() - 1
	
	while left <= right:
		var mid: int = (left + right) / 2
		if sorted_arr[mid] == num: return Vector2i(mid, mid)
		if num < sorted_arr[mid]: right = mid - 1
		else: left = mid + 1
	
	return Vector2i(left, right)


static func float32_array_find_closest(num: int, sorted_arr: PackedFloat32Array) -> int:
	
	var n: int = sorted_arr.size()
	if n == 0: return -1
	elif num <= sorted_arr[0]: return 0
	elif num >= sorted_arr[n - 1]: return n - 1
	
	var leftright: Vector2i = float32_array_find_leftright(num, sorted_arr)
	
	if abs(sorted_arr[leftright.x] - num) < abs(sorted_arr[leftright.y] - num): return leftright.x
	else: return leftright.y

static func float32_array_find_leftright(num: int, sorted_arr: PackedFloat32Array) -> Vector2i:
	
	var left: int = 0
	var right: int = sorted_arr.size() - 1
	
	while left <= right:
		var mid: int = (left + right) / 2
		if sorted_arr[mid] == num: return Vector2i(mid, mid)
		if num < sorted_arr[mid]: right = mid - 1
		else: left = mid + 1
	
	return Vector2i(left, right)


static func vec2_array_insert_packed(arr_a: PackedVector2Array, idx: int, arr_b: PackedVector2Array) -> PackedVector2Array:
	if idx < 0 or idx > arr_a.size():
		return arr_a
	var left: PackedVector2Array = arr_a.slice(0, idx)
	var right: PackedVector2Array = arr_a.slice(idx)
	
	return left + arr_b + right

static func vec2_array_get_reordered(arr: PackedVector2Array, start_idx: int) -> PackedVector2Array:
	return arr.slice(start_idx) + arr.slice(0, start_idx)
