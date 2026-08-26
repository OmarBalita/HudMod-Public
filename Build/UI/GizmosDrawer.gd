#############################################################################
##  This file is part of: HudMod Video Editor                              ##
##  https://omar-top.itch.io/hudmod-video-editor                           ##
## ----------------------------------------------------------------------- ##
##  Copyright © 2026 Omar Mohammed Balita.                                 ##
## ----------------------------------------------------------------------- ##
## GPLv3                                                                   ##
#############################################################################
class_name GizmosDrawer extends SelectContainer

enum GizmoType {
	GIZMO_TYPE_LINE,
	GIZMO_TYPE_RECT,
	GIZMO_TYPE_CIRCLE
}

var layers_profiles: Dictionary[LayerRes, GizmosProfile]

var snap_raw_data: Array[Dictionary]
var profiles_raw_data: Array[Dictionary]
var custom_raw_data: Array[Dictionary]

var main_snapping_points: PackedVector2Array

var viewport_canvas_transform: Transform2D
var scale_factor: float
var screen_offset: Vector2




func get_main_snapping_points() -> PackedVector2Array: return main_snapping_points
func set_main_snapping_points(new_val: PackedVector2Array) -> void: main_snapping_points = new_val


func update_viewport_canvas_transformation_props() -> void:
	
	var viewport: SubViewport = Scene2.viewport
	viewport_canvas_transform = viewport.canvas_transform
	var tex_size: Vector2i = viewport.size
	scale_factor = minf(
		size.x / tex_size.x,
		size.y / tex_size.y
	)
	var displayed_size: Vector2 = tex_size * scale_factor
	screen_offset = (size - displayed_size) * .5

func update_main_snapping_points() -> void:
	
	main_snapping_points.clear()
	
	var vp_size_h: Vector2i = Scene2.viewport.size / 2
	var vp_right: Vector2 = Vector2(vp_size_h.x, .0)
	var vp_down: Vector2 = Vector2(.0, vp_size_h.y)
	
	main_snapping_points.append_array([
		world2d_to_editor_screen(Vector2.ZERO),
		world2d_to_editor_screen(vp_right),
		world2d_to_editor_screen(-vp_right),
		world2d_to_editor_screen(vp_down),
		world2d_to_editor_screen(-vp_down)
	])


func try_snap(point: Vector2) -> Vector2:
	
	var main_vp_point: Vector2 = world2d_to_editor_screen(point)
	
	var x: float = main_vp_point.x
	var y: float = main_vp_point.y
	var dist_x: float = 10.
	var dist_y: float = 10.
	
	for other_point: Vector2 in main_snapping_points:
		
		var new_dist_x: float = absf(other_point.x - main_vp_point.x)
		var new_dist_y: float = absf(other_point.y - main_vp_point.y)
		
		if new_dist_x < dist_x:
			x = other_point.x
			dist_x = new_dist_x
		
		if new_dist_y < dist_y:
			y = other_point.y
			dist_y = new_dist_y
	
	var target_vp_point: Vector2 = Vector2(x, y)
	var target_point: Vector2 = editor_screen_to_world2d(target_vp_point)
	
	if x != main_vp_point.x:
		snap_raw_data.append({
			&"type": GizmoType.GIZMO_TYPE_LINE,
			&"args": Display2DClipRes.line_args(Vector2(target_vp_point.x, .0), Vector2(target_vp_point.x, size.y), Color.GREEN)
		})
	
	if y != main_vp_point.y:
		snap_raw_data.append({
			&"type": GizmoType.GIZMO_TYPE_LINE,
			&"args": Display2DClipRes.line_args(Vector2(.0, target_vp_point.y), Vector2(size.x, target_vp_point.y), Color.RED)
		})
	
	return target_point

func get_closer_snap(points: Dictionary[StringName, Vector2]) -> Dictionary[StringName, Variant]:
	
	var closer_xkey: StringName = &""
	var closer_xpos: float = .0
	var closer_xdist: float = INF
	
	var closer_ykey: StringName = &""
	var closer_ypos: float = .0
	var closer_ydist: float = INF
	
	for key: StringName in points:
		var point: Vector2 = points[key]
		var snapped_point: Vector2 = try_snap(point)
		
		var xdist: float = abs(snapped_point.x - point.x)
		var ydist: float = abs(snapped_point.y - point.y)
		
		if xdist < closer_xdist and xdist > .01:
			closer_xkey = key
			closer_xpos = snapped_point.x
			closer_xdist = xdist
		
		if ydist < closer_ydist and ydist > .01:
			closer_ykey = key
			closer_ypos = snapped_point.y
			closer_ydist = xdist
	
	return {
		&"xkey": closer_xkey,
		&"xval": closer_xpos,
		&"ykey": closer_ykey,
		&"yval": closer_ypos
	}




func get_snap_raw_data() -> Array[Dictionary]: return snap_raw_data
func set_snap_raw_data(new_val: Array[Dictionary]) -> void: snap_raw_data = new_val

func get_profiles_raw_data() -> Array[Dictionary]: return profiles_raw_data
func set_profiles_raw_data(new_val: Array[Dictionary]) -> void: profiles_raw_data = new_val

func get_custom_raw_data() -> Array[Dictionary]: return custom_raw_data
func set_custom_raw_data(new_val: Array[Dictionary]) -> void: custom_raw_data = new_val

func get_viewport_canvas_transform() -> Transform2D: return viewport_canvas_transform
func set_viewport_canvas_transform(new_val: Transform2D) -> void: viewport_canvas_transform = new_val

func get_scale_factor() -> float: return scale_factor
func set_scale_factor(new_val: float) -> void: scale_factor = new_val

func get_screen_offset() -> Vector2: return screen_offset
func set_screen_offset(new_val: Vector2) -> void: screen_offset = new_val



func _update_selectables_at(clip_res: MediaClipRes) -> void:
	var layers_body: TimeLine2.LayersSelectContainer = EditorServer.time_line2.layers_body
	
	var layers: Array[LayerRes] = clip_res.layers
	
	clear_selectable_ports()
	
	for layer_idx: int in layers.size():
		
		var layer_res: LayerRes = layers[layer_idx]
		
		var spawned_clip_res: MediaClipRes = layer_res.displayed_clip_res
		
		if spawned_clip_res == null: continue
		if spawned_clip_res is not Display2DClipRes: continue
		
		var frame: int = layer_res.displayed_frame
		
		spawned_clip_res = spawned_clip_res as Display2DClipRes
		add_selectable_port(layer_idx, {frame: spawned_clip_res})
		
		if layers_body.is_val_selected(layer_idx, frame):
			select_val(layer_idx, frame)


func _update_layers_profiles_at(owner_clip_res: MediaClipRes) -> void:
	layers_profiles.clear()
	var layers: Array[LayerRes] = owner_clip_res.layers
	for layer_res: LayerRes in layers:
		layers_profiles[layer_res] = GizmosProfile.new()


func _try_update_layers_profiles_gizmos_methods() -> void:
	
	for layer_res: LayerRes in layers_profiles:
		_try_update_layer_profile_gizmos_method(layer_res)

func _try_update_layer_profile_gizmos_method(layer_res: LayerRes) -> void:
	var profile: GizmosProfile = layers_profiles[layer_res]
	var spawned_clip_res: MediaClipRes = layer_res.displayed_clip_res
	
	if spawned_clip_res == profile.clip_res:
		return
	
	if spawned_clip_res == null or spawned_clip_res is not Display2DClipRes:
		profile.set_clip_res(null)
		profile.set_gizmos([])
		return
	
	spawned_clip_res = spawned_clip_res as Display2DClipRes
	
	profile.set_clip_res(spawned_clip_res)
	profile.set_gizmos(spawned_clip_res._get_gizmos())


func _update_all_gizmos() -> void:
	
	profiles_raw_data.clear()
	
	for layer_res: LayerRes in layers_profiles:
		
		var profile: GizmosProfile = layers_profiles[layer_res]
		var clip_res: Display2DClipRes = profile.clip_res
		
		if not clip_res_has_gizmos(clip_res): continue
		
		var gizmos: Array[Callable] = profile.get_gizmos()
		var gizmos_raw_data: Array[Dictionary]
		
		for idx: int in gizmos.size():
			var gizmos_method: Callable = gizmos[idx]
			gizmos_raw_data.append_array(gizmos_method.call())
		
		profile.set_gizmos_raw_data(gizmos_raw_data)
		profiles_raw_data.append_array(gizmos_raw_data)
	
	queue_redraw()


func update_when_layers_changed(opened_clip_res: MediaClipRes) -> void:
	_update_selectables_at(opened_clip_res)
	_update_layers_profiles_at(opened_clip_res)
	_try_update_layers_profiles_gizmos_methods()
	_update_all_gizmos()

func add_new_layer(layer_res: LayerRes) -> void:
	layers_profiles[layer_res] = GizmosProfile.new()
	_try_update_layer_profile_gizmos_method(layer_res)

func free_layer(layer_res: LayerRes) -> void:
	layers_profiles.erase(layer_res)


func _ready() -> void:
	
	super()
	
	IS.set_base_panel_settings(self, IS.style_box_empty)
	clip_contents = true
	
	shortcut_node.key = &"Viewport"
	shortcut_node.load_shortcuts_from_settings()
	
	resized.connect(_on_resized)
	ProjectServer2.project_opened.connect(_on_project_server2_project_opened)
	ProjectServer2.opened_clip_res_changed.connect(_on_project_server2_opened_clip_res_changed)
	EditorServer.time_line2.layers_body.selected_changed.connect(_on_timeline_layers_body_selected_changed)
	EditorServer.properties.property_changed.connect(_on_properties_property_changed)
	PlaybackServer.position_changed.connect(_on_playback_server_position_changed)


func _gui_input(event: InputEvent) -> void:
	
	snap_raw_data.clear()
	
	for layer_res: LayerRes in layers_profiles:
		
		var profile: GizmosProfile = layers_profiles[layer_res]
		var clip_res: Display2DClipRes = profile.clip_res
		
		if not clip_res_has_gizmos(clip_res):
			continue
		
		if clip_res._gizmos_input(event, profile.input_info):
			_update_all_gizmos()
			return
	
	if event is InputEventMouseButton:
		
		if event.button_index == MOUSE_BUTTON_LEFT and event.is_released():
			if event.position.distance_to(mouseevent_startpos) < 10.:
				_gui_input_try_select(event)
	
	super(event)
	queue_redraw()


func _gui_input_try_select(event: InputEventMouseButton) -> bool:
	var clips_ress_mouse_in: Array[Display2DClipRes]
	
	for port_idx: int in selectables:
		var port: Dictionary = selectables[port_idx]
		
		for idx: int in port:
			var clip_res: Display2DClipRes = port[idx]
			
			if clip_res_has_point(clip_res, event.position):
				clips_ress_mouse_in.append(clip_res)
	
	var try_delete: bool = event.alt_pressed
	var preclear: bool = not event.ctrl_pressed
	
	for clip_res: Display2DClipRes in clips_ress_mouse_in:
		var port_idx: int = clip_res.layer_index
		var idx: int = clip_res.clip_pos
		
		var is_selected: bool = is_val_selected(port_idx, idx)
		
		if (is_selected and not try_delete) or (not is_selected and try_delete):
			continue
		
		manage_val(port_idx, idx, try_delete, preclear)
		emit_selected_changed()
		return true
	
	if not clips_ress_mouse_in.is_empty():
		var first_clip_res: Display2DClipRes = clips_ress_mouse_in[0]
		manage_val(first_clip_res.layer_index, first_clip_res.clip_pos, try_delete, preclear)
		emit_selected_changed()
		return true
	
	return false



func _draw() -> void:
	_draw_raw_data(profiles_raw_data)
	_draw_raw_data(snap_raw_data)
	_draw_raw_data(custom_raw_data)

func _draw_raw_data(all_raw_data: Array[Dictionary]) -> void:
	
	for raw_data: Dictionary in all_raw_data:
		
		var type: GizmoType = raw_data.type
		var args: Array = raw_data.args
		
		match type:
			GizmoType.GIZMO_TYPE_LINE: draw_line.callv(args)
			GizmoType.GIZMO_TYPE_RECT: draw_rect.callv(args)
			GizmoType.GIZMO_TYPE_CIRCLE: draw_circle.callv(args)


func world2d_to_editor_screen(point: Vector2) -> Vector2:
	var viewport_point: Vector2 = viewport_canvas_transform * point
	return screen_offset + viewport_point * scale_factor

func editor_screen_to_world2d(point: Vector2) -> Vector2:
	var viewport_point: Vector2 = (point - screen_offset) / scale_factor
	return viewport_canvas_transform.affine_inverse() * viewport_point


func delete_selected_vals() -> void:
	var timeline: TimeLine2 = EditorServer.time_line2
	timeline.opened_clip_res.remove_clips(selected_to_coords())
	timeline.layers_body.emit_selected_changed()

func copy_selected_vals(cut: bool) -> void:
	EditorServer.time_line2.layers_body._copy_vals(selected, cut)

func past_selected_vals() -> void:
	EditorServer.time_line2.layers_body.past_selected_vals()

func emit_selected_changed() -> void:
	var timeline: TimeLine2 = EditorServer.time_line2
	var layers_body: TimeLine2.LayersSelectContainer = timeline.layers_body
	layers_body.selected = selected.duplicate(true)
	layers_body.focused = focused
	layers_body.emit_selected_changed()
	timeline.update_layers_clips_selection()
	super()

func clip_res_has_gizmos(clip_res: Display2DClipRes) -> bool:
	return clip_res != null and is_val_selected(clip_res.layer_index, clip_res.clip_pos)

func clip_res_get_rect2(clip_res: Display2DClipRes) -> Rect2:
	var canvas_item: CompCanvasItem = clip_res.get_canvas_item_comp()
	var size: Vector2 = clip_res.get_size(clip_res._get_global_canvas_transform(canvas_item)[2])
	var size_vp: Vector2 = size * scale_factor
	# Use the global canvas transform so selection hit-testing works correctly for nested clips
	var global_transform: Array = clip_res._get_global_canvas_transform(canvas_item)
	var global_pos: Vector2 = global_transform[0]
	
	return Rect2(world2d_to_editor_screen(global_pos) - size_vp / 2., size_vp)

func clip_res_get_screen_polygon(clip_res: Display2DClipRes) -> PackedVector2Array:
	var canvas_item: CompCanvasItem = clip_res.get_canvas_item_comp()
	var handles: Dictionary[StringName, Vector2] = clip_res._get_transform_handles(canvas_item)
	return PackedVector2Array([handles.c1, handles.c2, handles.c3, handles.c4])

func clip_res_has_point(clip_res: Display2DClipRes, screen_pos: Vector2) -> bool:
	return Geometry2D.is_point_in_polygon(screen_pos, clip_res_get_screen_polygon(clip_res))

func selectables_get_first_clip_res_mouse_in() -> MediaClipRes:
	var mouse_pos: Vector2 = get_local_mouse_position()
	
	for port_idx: int in selectables:
		var port: Dictionary = selectables[port_idx]
		for idx: int in port:
			var clip_res: Display2DClipRes = port[idx]
			if clip_res_has_point(clip_res, mouse_pos):
				return clip_res
	
	return null

func _request_box_selection() -> bool:
	return selectables_get_first_clip_res_mouse_in() == null

func _request_selection_box_select(port_idx: int, port_obj: Object, idx: int) -> bool:
	var clip_res: Display2DClipRes = selectables[port_idx][idx]
	
	var clip_res_polygon: PackedVector2Array = clip_res_get_screen_polygon(clip_res)
	var c1: Vector2 = clip_res_polygon[0]
	
	if c1 == clip_res_polygon[1] or c1 == clip_res_polygon[2]:
		return Geometry2D.is_point_in_polygon(c1, selectbox_polygon)
	
	var intersection: PackedVector2Array = Geometry2D.intersect_polygons(selectbox_polygon, clip_res_polygon)
	
	return not intersection.is_empty()






func _on_resized() -> void:
	await RenderingServer.frame_post_draw
	update_viewport_canvas_transformation_props()
	update_main_snapping_points()
	_update_all_gizmos()

func _on_project_server2_project_opened(project_res: ProjectRes) -> void:
	await RenderingServer.frame_post_draw
	update_viewport_canvas_transformation_props()
	update_main_snapping_points()
	_update_all_gizmos()

func _on_project_server2_opened_clip_res_changed(old_one: MediaClipRes, new_one: MediaClipRes) -> void:
	update_when_layers_changed(new_one)

func _on_timeline_layers_body_selected_changed() -> void:
	_update_selectables_at(EditorServer.time_line2.opened_clip_res)
	_update_all_gizmos()

func _on_properties_property_changed() -> void:
	#await RenderingServer.frame_post_draw
	#update_viewport_canvas_transformation_props()
	#update_main_snapping_points()
	#_update_all_gizmos()
	pass

func _on_playback_server_position_changed(position: int) -> void:
	update_viewport_canvas_transformation_props()
	update_main_snapping_points()
	_update_selectables_at(EditorServer.time_line2.opened_clip_res)
	_try_update_layers_profiles_gizmos_methods()
	_update_all_gizmos()


class GizmosProfile extends RefCounted:
	
	@export var clip_res: Display2DClipRes
	@export var gizmos: Array[Callable]
	@export var modulate: Color = Color.WHITE
	@export var locked: bool = false
	
	var gizmos_raw_data: Array[Dictionary]
	var input_info: Dictionary[StringName, Variant]
	
	func _back() -> int: return gizmos.size() - 1
	
	func get_clip_res() -> Display2DClipRes: return clip_res
	func set_clip_res(new_val: Display2DClipRes) -> void: clip_res = new_val
	
	func get_gizmos() -> Array[Callable]: return gizmos
	func set_gizmos(new_val: Array[Callable]) -> void: gizmos = new_val
	
	func get_modulate() -> Color: return modulate
	func set_modulate(new_val: Color) -> void: modulate = new_val
	
	func get_locked() -> bool: return locked
	func set_locked(new_val: bool) -> void: locked
	
	func get_gizmos_raw_data() -> Array[Dictionary]: return gizmos_raw_data
	func set_gizmos_raw_data(new_val: Array[Dictionary]) -> void: gizmos_raw_data = new_val
	
	func get_input_info() -> Dictionary[StringName, Variant]: return input_info
	func set_input_info(new_val: Dictionary[StringName, Variant]) -> void: input_info = new_val



