#############################################################################
##  This file is part of: HudMod Video Editor                              ##
##  https://omar-top.itch.io/hudmod-video-editor                           ##
## ----------------------------------------------------------------------- ##
##  Copyright © 2026 Omar Mohammed Balita.                                 ##
## ----------------------------------------------------------------------- ##
## GPLv3                                                                   ##
#############################################################################
class_name CompTextExtrude extends Text2DComponentRes

enum DrawMode {
	MODE_POLYGON,
	MODE_POLYLINE
}

@export var generate_component: ComponentPath:
	set(val):
		await until_ready()
		val.owner = self
		val.comps_ignored.append(self)
		val.component_path_changed.connect(_on_generate_component_path_changed)
		generate_component = val
		is_dirty = true

@export var direction: float = .0:
	set(val):
		if direction != val:
			direction = val
			is_dirty = true
@export var length: float = 25.:
	set(val):
		if length != val:
			length = val
			is_dirty = true
@export var scale: float = 1.:
	set(val):
		if scale != val:
			scale = val
			is_dirty = true

@export var color: Color = Color.WHITE
@export var use_gradient: bool = false
@export var gradient: ColorRangeRes:
	set(val):
		if gradient: gradient.res_changed.disconnect(emit_res_changed)
		if val: val.res_changed.connect(emit_res_changed)
		gradient = val

@export var draw_mode: DrawMode
@export var postdraw: bool = false
@export_range(1, 1000) var width: int = 1

var result: Dictionary[int, Array]

var is_dirty: bool = false

func get_result() -> Dictionary[int, Array]: return result
func set_result(new_val: Dictionary[int, Array]) -> void: result = new_val

func set_owner(new_owner: MediaClipRes) -> void:
	super(new_owner)
	generate_component = ComponentPath.new()
	gradient = ColorRangeRes.new()

func _get_exported_props() -> Dictionary[StringName, ExportInfo]:
	return {
		&"generate_component": export([generate_component]),
		
		&"direction": export(float_args(direction, -INF, INF, .01, .5)),
		&"length": export(float_args(length, .0, 100_000., .01, .2)),
		&"scale": export(float_args(scale, .0)),
		
		&"Color": export_method(ExportMethodType.METHOD_ENTER_CATEGORY),
		&"color": export(color_args(color)),
		&"use_gradient": export(bool_args(use_gradient)),
		&"gradient": export([gradient], [get.bind(&"use_gradient"), [true]]),
		&"_Color": export_method(ExportMethodType.METHOD_EXIT_CATEGORY),
		
		&"Draw": export_method(ExportMethodType.METHOD_ENTER_CATEGORY),
		&"draw_mode": export(options_args(draw_mode, DrawMode)),
		&"postdraw": export(bool_args(postdraw)),
		&"width": export(int_args(draw_mode, 1, 1000), [get.bind(&"draw_mode"), [1]]),
		&"_Draw": export_method(ExportMethodType.METHOD_EXIT_CATEGORY)
	}

func _process(frame: int) -> void:
	
	if is_dirty:
		generate_extrusion()
	
	var max_idx: float = float(owner.text.length())
	
	var result_keys: Array[int] = result.keys()
	
	var arr_forloop: Array
	
	var offset: Vector2 = _get_drop_offset()
	if offset.x > .0: arr_forloop = range(result_keys.size())
	else: arr_forloop = range(result_keys.size() - 1, -1, -1)
	
	var submit_func: Callable
	if draw_mode == DrawMode.MODE_POLYGON: submit_func = _submit_postdraw_polygon if postdraw else _submit_predraw_polygon
	else: submit_func = _submit_postdraw_polyline if postdraw else _submit_predraw_polyline
	
	var _get_color_func: Callable = color_gradient_func if use_gradient else color_base_func
	
	for idx: int in arr_forloop:
		var char_idx: int = result_keys[idx]
		for rect: PackedVector2Array in result[char_idx]:
			submit_func.call(rect, _get_color_func.call(char_idx / max_idx))

func color_base_func(char_ratio: float) -> Color: return color
func color_gradient_func(char_ratio: float) -> Color: return color * gradient.sample(char_ratio)


func _submit_postdraw_polygon(rect: PackedVector2Array, color: Color) -> void: submit_polygon_postdraw(rect, PackedColorArray([color]))
func _submit_predraw_polygon(rect: PackedVector2Array, color: Color) -> void: submit_polygon_predraw(rect, PackedColorArray([color]))
func _submit_postdraw_polyline(rect: PackedVector2Array, color: Color) -> void: submit_polyline_postdraw(rect, color, width, true)
func _submit_predraw_polyline(rect: PackedVector2Array, color: Color) -> void: submit_polyline_predraw(rect, color, width, true)

func generate_extrusion() -> void:
	
	result.clear()
	
	#var gen_shape_comp: CompTextGenShape
	#for comp: ComponentRes in owner.get_section_comps_absolute("Text"):
		#if comp is CompTextGenShape:
			#gen_shape_comp = comp
			#break
	#
	#if not gen_shape_comp:
		#return
	
	var _gen_comp: ComponentRes = generate_component.component
	
	if not _gen_comp: return
	if not _gen_comp.has_method(&"get_result"): return
	
	var comp_result: Dictionary[int, Array] = _gen_comp.result
	
	var offset: Vector2 = _get_drop_offset()
	
	for global_idx: int in comp_result:
		var paths: Array = comp_result[global_idx]
		result[global_idx] = _get_char_extrusion(paths, offset)
	
	result.sort()

func _get_char_extrusion(paths: Array, offset: Vector2) -> Array[PackedVector2Array]:
	
	var rects: Array[PackedVector2Array]
	var colors: PackedColorArray = PackedColorArray([color])
	
	for path: PackedVector2Array in paths:
		
		var path_size: int = path.size()
		
		if path_size < 2:
			continue
		
		for path_idx: int in path_size:
			
			var p1: Vector2 = path[path_idx]
			var p2: Vector2 = path[(path_idx + 1) % path_size]
			
			var p1_back: Vector2 = p1 * scale + offset
			var p2_back: Vector2 = p2 * scale + offset
			
			var rect:= PackedVector2Array([p1, p2, p2_back, p1_back])
			rects.append(rect)
	
	return rects

func _get_drop_offset() -> Vector2:
	var dir: float = deg_to_rad(direction)
	return Vector2(cos(dir), sin(dir)) * length


func _on_generate_component_path_changed(new_comp: ComponentRes) -> void:
	is_dirty = true
	_process_parent_here()






