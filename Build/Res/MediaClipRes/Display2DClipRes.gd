#############################################################################
##  This file is part of: HudMod Video Editor                              ##
##  https://omar-top.itch.io/hudmod-video-editor                           ##
## ----------------------------------------------------------------------- ##
##  Copyright © 2026 Omar Mohammed Balita.                                 ##
## ----------------------------------------------------------------------- ##
## GPLv3                                                                   ##
#############################################################################
@icon("res://Asset/Icons/Objects/empty-object-2d.png")
class_name Display2DClipRes extends MediaClipRes

signal pre_shader_material_changed()
signal post_shader_material_changed()
signal shader_pipeline_builded()

var pre_shader_material: ShaderMaterial: set = _set_pre_shader_material
var ppsm: Array[ShaderMaterial]
var ppr: PingPongRenderer
var post_shader_material: ShaderMaterial: set = _set_post_shader_material

var mat_process_id: int


static func get_explorer_section() -> StringName: return &"Object2D"
static func get_properties_section() -> StringName: return &"Display2D"
static func get_media_clip_info() -> Dictionary[StringName, String]:
	return {
		&"title": "Object2D",
		&"Description": ""
	}
static func get_icon() -> Texture2D: return preload("res://Asset/Icons/Objects/empty-object-2d.png")

func _set_pre_shader_material(val: ShaderMaterial) -> void:
	pre_shader_material = val
	pre_shader_material_changed.emit()

func _set_post_shader_material(val: ShaderMaterial) -> void:
	post_shader_material = val
	post_shader_material_changed.emit()

func _init_clip_res() -> void:
	add_component(&"Display2D", CompCanvasItem.new(), true)

func get_pre_shader_material() -> ShaderMaterial:
	return pre_shader_material

func set_pre_shader_material(new_shader_material: ShaderMaterial) -> void:
	pre_shader_material = new_shader_material

func get_post_shader_material() -> ShaderMaterial:
	return post_shader_material

func set_post_shader_material(new_shader_material: ShaderMaterial) -> void:
	post_shader_material = new_shader_material


enum _TransformationEditMode {
	EDIT_MODE_NONE,
	EDIT_MODE_CENTER,
	EDIT_MODE_ROTATION,
	EDIT_MODE_SCALE_C1,
	EDIT_MODE_SCALE_C2,
	EDIT_MODE_SCALE_C3,
	EDIT_MODE_SCALE_C4,
	EDIT_MODE_SCALE_UP,
	EDIT_MODE_SCALE_RIGHT,
	EDIT_MODE_SCALE_DOWN,
	EDIT_MODE_SCALE_LEFT
}

const _PRESS_MAX_DIST: float = 10.
const _DRAG_MIN_DIST: float = 10.
const _ROTATION_HANDLE_OFFSET: float = 30.

const _SCALE_HANDLE_MODES: Dictionary[StringName, _TransformationEditMode] = {
	&"c1": _TransformationEditMode.EDIT_MODE_SCALE_C1,
	&"c2": _TransformationEditMode.EDIT_MODE_SCALE_C2,
	&"c3": _TransformationEditMode.EDIT_MODE_SCALE_C3,
	&"c4": _TransformationEditMode.EDIT_MODE_SCALE_C4,
	&"up": _TransformationEditMode.EDIT_MODE_SCALE_UP,
	&"right": _TransformationEditMode.EDIT_MODE_SCALE_RIGHT,
	&"down": _TransformationEditMode.EDIT_MODE_SCALE_DOWN,
	&"left": _TransformationEditMode.EDIT_MODE_SCALE_LEFT,
}

func _get_gizmos() -> Array[Callable]:
	var gizmos: Array[Callable] = [_gizmos_transform]
	loop_components(
		func(comp_res: ComponentRes) -> void:
			gizmos.append_array(comp_res._get_gizmos())
	)
	return gizmos

func _gizmos_input(event: InputEvent, info: Dictionary[StringName, Variant]) -> bool:
	
	var canvas_item: CompCanvasItem = get_canvas_item_comp()
	if not canvas_item: return false
	
	if event is InputEventMouseButton:
		
		if event.button_index == MOUSE_BUTTON_LEFT:
			
			if event.is_pressed():
				var picked_edit_mode: _TransformationEditMode = _pick_edit_mode(canvas_item, event.position, info)
				info.set(&"edit_mode", picked_edit_mode)
				if picked_edit_mode != _TransformationEditMode.EDIT_MODE_NONE:
					info.set(&"button_event", event)
					return true
			else:
				info.clear()
			
			info.set(&"button_event", event)
	
	elif event is InputEventMouseMotion:
		
		var edit_mode: _TransformationEditMode = info.get(&"edit_mode", 0)
		
		if edit_mode:
			
			var button_event: InputEventMouseButton = info.get(&"button_event")
			
			if info.get(&"is_dragging", false):
				_apply_edit_mode(canvas_item, edit_mode, event, info)
				process_here()
				
				for clip_res: MediaClipRes in EditorServer.properties.curr_clip_ress:
					if clip_res is not Display2DClipRes: continue
					clip_res.update_controllers(clip_res.get_canvas_item_comp(), curr_frame)
			
			else:
				var event_pos_delta: Vector2 = event.position - button_event.position
				if event_pos_delta.length() >= _DRAG_MIN_DIST:
					info.set(&"is_dragging", true)
			
			return true
	
	for section_key: StringName in components:
		var section: Array = components[section_key]
		for comp_res: ComponentRes in section:
			if comp_res._gizmos_input(event, info):
				return true
	
	return false

func _pick_edit_mode(canvas_item: CompCanvasItem, mouse_pos: Vector2, info: Dictionary[StringName, Variant]) -> _TransformationEditMode:
	
	var gizmos_drawer: GizmosDrawer = EditorServer.player.gizmos_drawer
	var global_transform: Array = _get_global_canvas_transform(canvas_item)
	var global_pos: Vector2 = global_transform[0]
	
	var vp_center: Vector2 = gizmos_drawer.world2d_to_editor_screen(global_pos)
	
	if vp_center.distance_to(mouse_pos) <= _PRESS_MAX_DIST:
		
		info.set(&"pos_initial", canvas_item.position)
		info.set(&"poss_initial", EditorServer.properties.curr_clips_ress_map(
			MediaClipResPath.node2d_cond,
			func(idx: int, clip_res: Display2DClipRes) -> Vector2: return clip_res.get_canvas_item_comp().position
		))
		
		return _TransformationEditMode.EDIT_MODE_CENTER
	
	var handles: Dictionary[StringName, Vector2] = _get_transform_handles(canvas_item)
	
	if handles[&"rotation"].distance_to(mouse_pos) <= _PRESS_MAX_DIST:
		info.set(&"rotation_initial", canvas_item.rotation_degrees)
		# Compute the initial angle relative to the global center
		info.set(&"angle_initial", (gizmos_drawer.editor_screen_to_world2d(mouse_pos) - global_pos).angle())
		info.set(&"global_pos_at_rotation_start", global_pos)
		
		info.set(&"rotations_initial", EditorServer.properties.curr_clips_ress_map(
			MediaClipResPath.node2d_cond,
			func(idx: int, clip_res: Display2DClipRes) -> float: return clip_res.get_canvas_item_comp().rotation_degrees
		))
		
		return _TransformationEditMode.EDIT_MODE_ROTATION
	
	for key: StringName in _SCALE_HANDLE_MODES:
		if handles[key].distance_to(mouse_pos) <= _PRESS_MAX_DIST:
			_begin_scale_drag(canvas_item, info)
			return _SCALE_HANDLE_MODES[key]
	
	return _TransformationEditMode.EDIT_MODE_NONE

func _begin_scale_drag(canvas_item: CompCanvasItem, info: Dictionary[StringName, Variant]) -> void:
	var global_transform: Array = _get_global_canvas_transform(canvas_item)
	var global_pos: Vector2 = global_transform[0]
	var global_rot: float = global_transform[1]
	
	info.set(&"scale_initial", canvas_item.scale)
	# Store global rotation and global center so _to_local_unrotated works correctly for nested clips
	info.set(&"rotation_at_scale_start", global_rot)
	info.set(&"center_at_scale_start", global_pos)
	info.set(&"size_half_initial", get_size(canvas_item.scale) / 2.)
	
	info.set(&"scales_initial", EditorServer.properties.curr_clips_ress_map(
		MediaClipResPath.node2d_cond,
		func(idx: int, clip_res: Display2DClipRes) -> Vector2:
			return clip_res.get_canvas_item_comp().scale
	))

func _apply_edit_mode(canvas_item: CompCanvasItem, edit_mode: _TransformationEditMode, event: InputEventMouseMotion, info: Dictionary[StringName, Variant]) -> void:
	var gizmos_drawer: GizmosDrawer = EditorServer.player.gizmos_drawer
	
	var vp_pos: Vector2 = event.position
	var world_pos: Vector2 = gizmos_drawer.editor_screen_to_world2d(vp_pos)
	var snapped_world_pos: Vector2 = gizmos_drawer.try_snap(world_pos)
	
	match edit_mode:
		_TransformationEditMode.EDIT_MODE_CENTER:
			_apply_translation(canvas_item, snapped_world_pos, gizmos_drawer, event, info)
		_TransformationEditMode.EDIT_MODE_ROTATION:
			_apply_rotation(canvas_item, world_pos, event, info)
		_TransformationEditMode.EDIT_MODE_SCALE_C1, _TransformationEditMode.EDIT_MODE_SCALE_C2, _TransformationEditMode.EDIT_MODE_SCALE_C3, _TransformationEditMode.EDIT_MODE_SCALE_C4:
			_apply_corner_scale(canvas_item, snapped_world_pos, event, info)
		_TransformationEditMode.EDIT_MODE_SCALE_UP, _TransformationEditMode.EDIT_MODE_SCALE_DOWN:
			_apply_axis_scale(canvas_item, snapped_world_pos, false, event, info)
		_TransformationEditMode.EDIT_MODE_SCALE_LEFT, _TransformationEditMode.EDIT_MODE_SCALE_RIGHT:
			_apply_axis_scale(canvas_item, snapped_world_pos, true, event, info)


func _apply_translation(canvas_item: CompCanvasItem, snapped_world_pos: Vector2, gizmos_drawer: GizmosDrawer, event: InputEventMouseMotion, info: Dictionary[StringName, Variant]) -> void:
	# Convert the snapped world position to local space (undoes parent transforms)
	var local_pos: Vector2 = _world_pos_to_local(snapped_world_pos)
	canvas_item.set_prop_and_emit(&"position", local_pos)
	
	var local_points: Dictionary[StringName, Vector2] = _get_transform_local_points(canvas_item)
	var world_points: Dictionary[StringName, Vector2] = _local_points_to_world_points(canvas_item, local_points)
	world_points.erase(&"rotation")
	
	var closer_snap: Dictionary[StringName, Variant] = gizmos_drawer.get_closer_snap(world_points)
	var xkey: StringName = closer_snap.xkey
	var ykey: StringName = closer_snap.ykey
	
	# Use global rotation for rotating the edge offset correctly
	var gt: Array = _get_global_canvas_transform(canvas_item)
	var g_rot_rad: float = deg_to_rad(gt[1])
	
	# The target world position after considering edge snapping
	var target_world: Vector2 = Vector2(
		snapped_world_pos.x if xkey.is_empty() else closer_snap.xval - local_points[xkey].rotated(g_rot_rad).x,
		snapped_world_pos.y if ykey.is_empty() else closer_snap.yval - local_points[ykey].rotated(g_rot_rad).y
	)
	
	# Convert the final target world position back to local
	var target_local: Vector2 = _world_pos_to_local(target_world)
	canvas_item.set_prop_and_emit(&"position", target_local)
	
	if EditorServer.time_line2.is_edit_multiple():
		var pos_delta: Vector2 = target_local - info.pos_initial
		var poss_initial: Array = info.poss_initial
		
		var idx: int
		for clip_res: MediaClipRes in EditorServer.properties.curr_clip_ress:
			if not MediaClipResPath.node2d_cond(clip_res): continue
			clip_res.get_canvas_item_comp().set_prop_and_emit(&"position", poss_initial[idx] + pos_delta)
			idx += 1

func _apply_rotation(canvas_item: CompCanvasItem, world_pos: Vector2, event: InputEventMouseMotion, info: Dictionary[StringName, Variant]) -> void:
	
	# Use the global center stored at the start of the rotation drag for angle computation
	var global_center: Vector2 = info.get(&"global_pos_at_rotation_start", canvas_item.position)
	var angle_now: float = (world_pos - global_center).angle()
	var angle_initial: float = info.get(&"angle_initial")
	var rotation_initial: float = info.get(&"rotation_initial")
	var rot_deg: float = rotation_initial + rad_to_deg(angle_now - angle_initial)
	
	const SNAP_THRESHOLD: float = 5.
	var nearest_snap: float = snappedf(rot_deg, 45.)
	
	if absf(rot_deg - nearest_snap) <= SNAP_THRESHOLD:
		rot_deg = nearest_snap
	
	canvas_item.set_prop_and_emit(&"rotation_degrees", rot_deg)
	
	if EditorServer.time_line2.is_edit_multiple():
		var rotation_delta: float = rot_deg - rotation_initial
		var rots_initial: Array = info.rotations_initial
		
		var idx: int
		for clip_res: MediaClipRes in EditorServer.properties.curr_clip_ress:
			if not MediaClipResPath.node2d_cond(clip_res): continue
			clip_res.get_canvas_item_comp().set_prop_and_emit(&"rotation_degrees", rots_initial[idx] + rotation_delta)
			idx += 1

func _apply_corner_scale(canvas_item: CompCanvasItem, world_pos: Vector2, event: InputEventMouseMotion, info: Dictionary[StringName, Variant]) -> void:
	var local_now: Vector2 = _to_local_unrotated(world_pos, info)
	var size_half_initial: Vector2 = info.get(&"size_half_initial")
	var scale_initial: Vector2 = info.get(&"scale_initial")
	
	var target_scale_x: float = scale_initial.x * (absf(local_now.x) / maxf(absf(size_half_initial.x), .001))
	var target_scale_y: float = scale_initial.y * (absf(local_now.y) / maxf(absf(size_half_initial.y), .001))
	var target_scale: Vector2
	
	if event.shift_pressed: target_scale = Vector2(target_scale_x, target_scale_y)
	else: target_scale = Vector2.ONE * maxf(target_scale_x, target_scale_y)
	
	var scale_ratio: Vector2 = Vector2(
		target_scale.x / maxf(absf(scale_initial.x), .001) * sign(scale_initial.x if scale_initial.x != 0 else 1.0),
		target_scale.y / maxf(absf(scale_initial.y), .001) * sign(scale_initial.y if scale_initial.y != 0 else 1.0)
	)
	
	canvas_item.set_prop_and_emit(&"scale", target_scale)
	
	if EditorServer.time_line2.is_edit_multiple():
		var scales_initial: Array = info.scales_initial
		
		var idx: int
		for clip_res: MediaClipRes in EditorServer.properties.curr_clip_ress:
			if not MediaClipResPath.node2d_cond(clip_res): continue
			var s0: Vector2 = scales_initial[idx]
			clip_res.get_canvas_item_comp().set_prop_and_emit(&"scale", Vector2(s0.x * scale_ratio.x, s0.y * scale_ratio.y))
			idx += 1

func _apply_axis_scale(canvas_item: CompCanvasItem, world_pos: Vector2, is_x_axis: bool, event: InputEventMouseMotion, info: Dictionary[StringName, Variant]) -> void:
	var local_now: Vector2 = _to_local_unrotated(world_pos, info)
	var size_half_initial: Vector2 = info.get(&"size_half_initial")
	var scale_initial: Vector2 = info.get(&"scale_initial")
	
	var scale_main: Vector2 = canvas_item.get_prop(&"scale")
	var target_scale: Vector2 = scale_main
	var axis_ratio: float = 1.0
	
	if is_x_axis:
		var target_scale_x: float = scale_initial.x * (absf(local_now.x) / maxf(absf(size_half_initial.x), .001))
		axis_ratio = target_scale_x / maxf(absf(scale_initial.x), .001) * sign(scale_initial.x if scale_initial.x != 0 else 1.0)
		target_scale = Vector2(target_scale_x, scale_main.y)
	else:
		var target_scale_y: float = scale_initial.y * (absf(local_now.y) / maxf(absf(size_half_initial.y), .001))
		axis_ratio = target_scale_y / maxf(absf(scale_initial.y), .001) * sign(scale_initial.y if scale_initial.y != 0 else 1.0)
		target_scale = Vector2(scale_main.x, target_scale_y)
	
	canvas_item.set_prop_and_emit(&"scale", target_scale)
	
	if EditorServer.time_line2.is_edit_multiple():
		
		var scales_initial: Array = info.scales_initial
		
		var idx: int
		for clip_res: MediaClipRes in EditorServer.properties.curr_clip_ress:
			if not MediaClipResPath.node2d_cond(clip_res): continue
			var s0: Vector2 = scales_initial[idx]
			var new_scale: Vector2 = s0
			if is_x_axis: new_scale.x = s0.x * axis_ratio
			else: new_scale.y = s0.y * axis_ratio
			clip_res.get_canvas_item_comp().set_prop_and_emit(&"scale", new_scale)
			idx += 1

func _to_local_unrotated(world_pos: Vector2, info: Dictionary[StringName, Variant]) -> Vector2:
	var center: Vector2 = info.get(&"center_at_scale_start")
	var rotation_initial: float = info.get(&"rotation_at_scale_start")
	# Use global center and global rotation so scale handles work correctly in nested clips
	return (world_pos - center).rotated(-deg_to_rad(rotation_initial))

## Returns [position, rotation_degrees, scale] accumulated globally from all
## Display2DClipRes ancestors, stopping at the first non-Display2DClipRes parent.
func _get_parent_global_transform() -> Array:
	# Collect ancestor chain (root-first) by walking up via `parent`
	var ancestors: Array[Display2DClipRes] = []
	var p: MediaClipRes = parent
	while p is Display2DClipRes:
		ancestors.push_front(p as Display2DClipRes)
		p = p.parent
	
	var g_pos:= Vector2.ZERO
	var g_rot: float = .0
	var g_scale:= Vector2.ONE
	
	for anc: Display2DClipRes in ancestors:
		var anc_ci: CompCanvasItem = anc.get_canvas_item_comp()
		var anc_rot_rad:= deg_to_rad(anc_ci.rotation_degrees)
		# Apply this ancestor: translate local origin by scaled+rotated parent position
		g_pos = g_pos + (anc_ci.position * g_scale).rotated(g_rot)
		g_rot = g_rot + anc_rot_rad
		g_scale = g_scale * anc_ci.scale
	
	return [g_pos, rad_to_deg(g_rot), g_scale]

## Returns the global position, rotation_degrees, and effective scale of this clip's
## canvas item, taking all Display2DClipRes ancestors into account.
func _get_global_canvas_transform(canvas_item: CompCanvasItem) -> Array:
	var parent_transform: Array = _get_parent_global_transform()
	var g_pos: Vector2 = parent_transform[0]
	var g_rot: float = parent_transform[1]
	var g_scale: Vector2 = parent_transform[2]
	
	var local_pos: Vector2 = canvas_item.position
	var local_rot: float = canvas_item.rotation_degrees
	var local_scale: Vector2 = canvas_item.scale
	
	var world_pos: Vector2 = g_pos + (local_pos * g_scale).rotated(deg_to_rad(g_rot))
	var world_rot: float = g_rot + local_rot
	var world_scale: Vector2 = g_scale * local_scale
	
	return [world_pos, world_rot, world_scale]

## Converts a global world position back to the local position for this clip's canvas item,
## undoing all ancestor transforms.
func _world_pos_to_local(world_pos: Vector2) -> Vector2:
	var parent_transform: Array = _get_parent_global_transform()
	var g_pos: Vector2 = parent_transform[0]
	var g_rot: float = parent_transform[1]
	var g_scale: Vector2 = parent_transform[2]
	
	# Undo parent: local_pos = ((world_pos - g_pos).rotated(-g_rot)) / g_scale
	var rel: Vector2 = (world_pos - g_pos).rotated(-deg_to_rad(g_rot))
	return Vector2(
		rel.x / g_scale.x if g_scale.x != .0 else rel.x,
		rel.y / g_scale.y if g_scale.y != .0 else rel.y
	)

func _get_transform_handles(canvas_item: CompCanvasItem) -> Dictionary[StringName, Vector2]:
	var gizmos_drawer: GizmosDrawer = EditorServer.player.gizmos_drawer
	
	var local_points: Dictionary[StringName, Vector2] = _get_transform_local_points(canvas_item)
	var world_points: Dictionary[StringName, Vector2] = _local_points_to_world_points(canvas_item, local_points)
	
	var handles: Dictionary[StringName, Vector2] = {}
	for key: StringName in world_points:
		handles[key] = gizmos_drawer.world2d_to_editor_screen(world_points[key])
	
	return handles

func _get_transform_local_points(canvas_item: CompCanvasItem) -> Dictionary[StringName, Vector2]:
	var size_half: Vector2 = get_size(_get_global_canvas_transform(canvas_item)[2]) / 2.
	var points: Dictionary[StringName, Vector2] = {
		&"c1": Vector2(-size_half.x, -size_half.y),
		&"c2": Vector2(size_half.x, -size_half.y),
		&"c3": Vector2(size_half.x, size_half.y),
		&"c4": Vector2(-size_half.x, size_half.y),
		&"up": Vector2(0., -size_half.y),
		&"right": Vector2(size_half.x, 0.),
		&"down": Vector2(0., size_half.y),
		&"left": Vector2(-size_half.x, 0.),
		&"rotation": Vector2(size_half.x + _ROTATION_HANDLE_OFFSET, .0),
	}
	return points

func _local_points_to_world_points(canvas_item: CompCanvasItem, local_points: Dictionary[StringName, Vector2]) -> Dictionary[StringName, Vector2]:
	# Use the globally-accumulated transform so nested clips show Gizmos at the
	# correct world-space position.
	var gt: Array = _get_global_canvas_transform(canvas_item)
	var g_pos: Vector2 = gt[0]
	var g_rot_rad: float = deg_to_rad(gt[1])
	
	var world_points: Dictionary[StringName, Vector2] = {}
	for key: StringName in local_points:
		var world_point: Vector2 = g_pos + local_points[key].rotated(g_rot_rad)
		world_points[key] = world_point
	return world_points


func _gizmos_transform() -> Array[Dictionary]:
	
	var canvas_item: CompCanvasItem = get_canvas_item_comp()
	if not canvas_item: return []
	
	# Use the global canvas transform so the center circle is at the correct world position
	var gt: Array = _get_global_canvas_transform(canvas_item)
	var global_pos: Vector2 = gt[0]
	var vp_pos: Vector2 = EditorServer.player.gizmos_drawer.world2d_to_editor_screen(global_pos)
	var handles: Dictionary[StringName, Vector2] = _get_transform_handles(canvas_item)
	var c1: Vector2 = handles[&"c1"]
	var c2: Vector2 = handles[&"c2"]
	var c3: Vector2 = handles[&"c3"]
	var c4: Vector2 = handles[&"c4"]
	
	var result: Array[Dictionary] = [
		{
			&"type": GizmosDrawer.GizmoType.GIZMO_TYPE_CIRCLE,
			&"args": circle_args(vp_pos, 10.),
		},
	]
	
	result.append_array([
		{&"type": 0, &"args": line_args(c1, c2)},
		{&"type": 0, &"args": line_args(c2, c3)},
		{&"type": 0, &"args": line_args(c3, c4)},
		{&"type": 0, &"args": line_args(c4, c1)},
	])
	result.append_array([
		{&"type": 2, &"args": circle_args(c1, 5., Color.GRAY, true, -1.)},
		{&"type": 2, &"args": circle_args(c2, 5., Color.GRAY, true, -1.)},
		{&"type": 2, &"args": circle_args(c3, 5., Color.GRAY, true, -1.)},
		{&"type": 2, &"args": circle_args(c4, 5., Color.GRAY, true, -1.)},
		{&"type": 2, &"args": circle_args(handles[&"up"], 5., Color.GRAY, true, -1.)},
		{&"type": 2, &"args": circle_args(handles[&"right"], 5., Color.GRAY, true, -1.)},
		{&"type": 2, &"args": circle_args(handles[&"down"], 5., Color.GRAY, true, -1.)},
		{&"type": 2, &"args": circle_args(handles[&"left"], 5., Color.GRAY, true, -1.)},
		{&"type": 2, &"args": circle_args(handles[&"rotation"], 6., Color.YELLOW, true, -1.)},
	])
	return result


static func line_args(from: Vector2, to: Vector2, color: Color = Color.GRAY, width: float = 2., antialiasing: bool = true) -> Array: return [from, to, color, width, antialiasing]
static func rect_args(rect2: Rect2, color: Color = Color.GRAY, filled: bool = false, width = 2., antialiasing: bool = true) -> Array: return [rect2, color, filled, width, antialiasing]
static func circle_args(pos: Vector2, radius: float, color: Color = Color.GRAY, filled: bool = false, width = 2., antialiasing: bool = true) -> Array: return [pos, radius, color, filled, width, antialiasing]


func get_canvas_item_comp() -> CompCanvasItem:
	return components.get(&"Display2D")[0]


func init_node(root_layer_idx: int, layer_idx: int, layer_res: LayerRes, frame: int) -> Node:
	return _init_node2d(root_layer_idx, layer_idx, layer_res, frame, Node2D.new())

func _init_node2d(root_layer_idx: int, layer_idx: int, layer_res: LayerRes, frame: int, node2d: Node2D) -> Node2D:
	node2d.visible = not layer_res.hidden
	
	var back_buffer_copy:= BackBufferCopy.new()
	back_buffer_copy.copy_mode = BackBufferCopy.COPY_MODE_VIEWPORT
	node2d.add_child(back_buffer_copy)
	
	return node2d

func enter(node: Node) -> void:
	curr_node.material = post_shader_material
	if ppsm: ppr = RenderFarm.pingpong_renderer_init(self)
	super(node)

func _process_comps(frame: int) -> void:
	super(frame)

func _after_process_comps(frame: int) -> void:
	await process_material(frame)
	super(frame)

func exit(node: Node) -> void:
	super(node)
	if ppr: RenderFarm.pingpong_renderer_free(self)

func process_material(frame: int) -> void:
	
	var frame_f: float = float(frame)
	
	mat_process_id += 1
	var curr_mat_process_id: int = mat_process_id
	
	if post_shader_material:
		post_shader_material.set_shader_parameter(&"time", frame_f)
	
	if ppsm:
		for sm: ShaderMaterial in ppsm:
			sm.set_shader_parameter(&"time", frame_f)
		
		if ppr.is_in_process:
			await ppr.process_finished
			if mat_process_id != curr_mat_process_id:
				return
		await process_passes_materials(1.)

func process_passes_materials(render_scale: float) -> void:
	await ppr.request_process_output(get_self_main_texture(), ppsm, render_scale)

func get_self_main_texture() -> Texture2D: return null
func get_self_texture() -> Texture2D: return ppr.get_output_texture() if ppr else get_self_main_texture()
func get_size(scale: Vector2) -> Vector2: return Vector2.ZERO

func build_shader_pipeline() -> void:
	
	ppsm.clear()
	
	var used_names: PackedStringArray
	
	var pre_global_params_section: String
	var pre_fragment_section: String
	var pre_vertex_section: String
	
	var post_global_params_section: String
	var post_fragment_section: String
	var post_vertex_section: String
	
	var owner_global_params: String = _format_shader_snip(_get_shader_global_param_snip(), {}, used_names, true)
	var owner_fragment: String = _format_shader_snip(_get_shader_fragment_snip(), {}, used_names, false)
	var owner_vertex: String = _format_shader_snip(_get_shader_vertex_snip(), {}, used_names, false)
	
	if _shader_is_post():
		post_global_params_section = owner_global_params
		post_fragment_section = owner_fragment
		post_vertex_section = owner_vertex
	else:
		pre_global_params_section = owner_global_params
		pre_fragment_section = owner_fragment
		pre_vertex_section = owner_vertex
	
	for section: StringName in components:
		var section_comps: Array = components[section]
		for comp_res: ComponentRes in section_comps:
			
			if not comp_res.enabled:
				continue
			
			if comp_res is PassShaderComponentRes:
				ppsm.append(comp_res.create_pass_shader_material())
			
			elif comp_res is SnippetShaderComponentRes:
				var params_names_list: Dictionary[String, String]
				
				var global_params_snip: String = _format_shader_snip(comp_res._get_shader_global_params_snip(), params_names_list, used_names, true)
				var fragment_snip: String = _format_shader_snip(comp_res._get_shader_fragment_snip(), params_names_list, used_names, false)
				var vertex_snip: String = _format_shader_snip(comp_res._get_shader_vertex_snip(), params_names_list, used_names, false)
				
				if global_params_snip: post_global_params_section += "\n" + global_params_snip
				if fragment_snip: post_fragment_section += "\n" + fragment_snip
				if vertex_snip: post_vertex_section += "\n" + vertex_snip
				
				comp_res.set_shader_params_names_list(params_names_list)
	
	var has_passes: bool = not ppsm.is_empty()
	
	if Scene2.curr_nodes_has(self):
		
		if ppr:
			if not has_passes:
				RenderFarm.pingpong_renderer_free(self)
				ppr = null
		
		elif has_passes:
			ppr = RenderFarm.pingpong_renderer_init(self)
	
	if has_passes:
		var pre_shader_code: String = str(
			_get_shader_header(), "\n",
			"\nuniform float time;",
			pre_global_params_section, "\n",
			_get_shader_fragment(pre_fragment_section), "\n",
			_get_shader_vertex(pre_vertex_section)
		)
		pre_shader_material = ShaderMaterial.new()
		var shader: Shader = Shader.new()
		shader.code = pre_shader_code
		pre_shader_material.shader = shader
		ppsm.insert(0, pre_shader_material)
	
	else:
		post_global_params_section = pre_global_params_section + "\n" + post_global_params_section
		post_fragment_section = pre_fragment_section + "\n" + post_fragment_section
		post_vertex_section = pre_vertex_section + "\n" + post_vertex_section
	
	if post_global_params_section.is_empty() and post_fragment_section.is_empty() and post_vertex_section.is_empty():
		return
	
	post_fragment_section = _get_shader_fragment(post_fragment_section)
	post_vertex_section = _get_shader_vertex(post_vertex_section)
	
	var post_shader_code: String = str(
		_get_shader_header(), "\n",
		"\nuniform float time;",
		post_global_params_section, "\n",
		post_fragment_section, "\n",
		post_vertex_section
	)
	
	await RenderingServer.frame_post_draw
	
	if post_shader_code.is_empty():
		post_shader_material = null
	else:
		var new_shader_mat:= ShaderMaterial.new()
		var new_shader:= Shader.new()
		new_shader.set_code(post_shader_code)
		new_shader_mat.set_shader(new_shader)
		post_shader_material = new_shader_mat
		
		if not has_passes:
			pre_shader_material = new_shader_mat
		
		for section_key: StringName in components:
			for comp_res: ComponentRes in components[section_key]:
				if comp_res is ShaderComponentRes and comp_res.enabled:
					comp_res._ready_shader()
	
	shared_data_clear()
	
	if curr_node:
		curr_node.material = post_shader_material
	
	shader_pipeline_builded.emit()



func _get_shader_header() -> String:
	return "shader_type canvas_item;\n#include \"res://Build/Shader/Global.gdshaderinc\"\nuniform sampler2D SCREEN_TEXTURE: hint_screen_texture, filter_linear_mipmap;\n"

func _get_shader_fragment(fragment_section: String) -> String:
	return "
void fragment() {
	vec3 color = COLOR.rgb;
	float alpha = COLOR.a;
" + fragment_section + "
	COLOR.rgb = color;
	COLOR.a = alpha;
}"

func _get_shader_vertex(vertex_section: String) -> String:
	return "
void vertex() {
	vec2 vertex = VERTEX;
	vec2 uv = UV;
	" + vertex_section + "
	VERTEX = vertex;
	UV = uv;
}"

static func _shader_is_post() -> bool: return true
func _get_shader_global_param_snip() -> String: return ""
func _get_shader_fragment_snip() -> String: return ""
func _get_shader_vertex_snip() -> String: return ""


static func _format_shader_snip(shader_snip: String, params_names_list: Dictionary[String, String], used_names: PackedStringArray, is_global: bool) -> String:
	var gen_id_func: Callable = StringHelper.generate_new_id.bind(used_names, 12, true)
	var shader_placeholders: PackedStringArray = StringHelper.extract_placeholders(shader_snip)
	var format_values: Dictionary[String, String] = {}
	
	for key: String in shader_placeholders:
		var code_key: String
		if is_global:
			code_key = gen_id_func.call()
			params_names_list[key] = code_key
		elif not params_names_list.has(key):
			code_key = gen_id_func.call()
		else:
			code_key = params_names_list[key]
		format_values[key] = code_key
	
	return shader_snip.format(format_values)

func emit_clip_res_changed() -> void:
	await build_shader_pipeline()
	super()

