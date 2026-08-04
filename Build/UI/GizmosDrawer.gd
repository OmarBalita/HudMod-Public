#############################################################################
##  This file is part of: HudMod Video Editor                              ##
##  https://omar-top.itch.io/hudmod-video-editor                           ##
## ----------------------------------------------------------------------- ##
##  Copyright © 2026 Omar Mohammed Balita.                                 ##
## ----------------------------------------------------------------------- ##
## GPLv3                                                                   ##
#############################################################################
class_name GizmosDrawer extends Control

enum GizmoType {
	GIZMO_TYPE_LINE,
	GIZMO_TYPE_RECT,
	GIZMO_TYPE_CIRCLE
}

var gizmos_profiles: Dictionary[Display2DClipRes, GizmosProfile]
var all_raw_data: Array[Dictionary]

static var _canvas_transform: Transform2D
static var _scale_factor: float
static var _offset: Vector2


func get_gizmos_profiles() -> Dictionary[Display2DClipRes, GizmosProfile]: return gizmos_profiles
func set_gizmos_profiles(new_val: Dictionary[Display2DClipRes, GizmosProfile]) -> void: gizmos_profiles = new_val

func clear_gizmos_profiles() -> void: gizmos_profiles.clear()

func _init_gizmos_profile(clip_res: Display2DClipRes) -> GizmosProfile:
	var profile:= GizmosProfile.new()
	profile.set_gizmos(clip_res._get_gizmos())
	return profile

func _register_gizmos_profile(clip_res: Display2DClipRes, profile: GizmosProfile) -> void:
	gizmos_profiles[clip_res] = profile

func _update_gizmos_profiles_by_selected_clips() -> void:
	
	var remained_clips_ress: Array[Display2DClipRes] = gizmos_profiles.keys()
	
	var layers_body: TimeLine2.LayersSelectContainer = EditorServer.time_line2.layers_body
	var selected: Dictionary[int, Dictionary] = layers_body.selected
	
	for layer_idx: int in selected:
		var port: Dictionary = selected[layer_idx]
		for frame: int in port:
			var clip_res: MediaClipRes = port[frame]
			if clip_res is not Display2DClipRes: continue
			_update_gizmos_profile_existent(clip_res)
			remained_clips_ress.erase(clip_res)
	
	for clip_res: MediaClipRes in remained_clips_ress:
		gizmos_profiles.erase(clip_res)

func _update_curr_gizmos_profiles_existent() -> void:
	for clip_res: MediaClipRes in gizmos_profiles:
		_update_gizmos_profile_existent(clip_res)

func _update_gizmos_profile_existent(clip_res: Display2DClipRes) -> void:
	
	if PlaybackServer.is_frame_at_clip_res(clip_res.clip_pos, clip_res):
		
		if gizmos_profiles.has(clip_res):
			if gizmos_profiles[clip_res] == null:
				_register_gizmos_profile(clip_res, _init_gizmos_profile(clip_res))
		else: _register_gizmos_profile(clip_res, _init_gizmos_profile(clip_res))
	
	else:
		gizmos_profiles[clip_res] = null


func update_all_gizmos() -> void:
	
	await RenderingServer.frame_post_draw
	
	var viewport: SubViewport = Scene2.viewport
	_canvas_transform = viewport.canvas_transform
	var tex_size: Vector2i = viewport.size
	_scale_factor = minf(
		size.x / tex_size.x,
		size.y / tex_size.y
	)
	var displayed_size: Vector2 = tex_size * _scale_factor
	_offset = (size - displayed_size) * .5
	
	all_raw_data.clear()
	
	for clip_res: Display2DClipRes in gizmos_profiles:
		
		if not clip_res.curr_node:
			continue
		
		var profile: GizmosProfile = gizmos_profiles[clip_res]
		if not profile: continue
		
		var gizmos: Array[Callable] = profile.get_gizmos()
		var gizmos_raw_data: Array[Dictionary]
		
		for idx: int in gizmos.size():
			var gizmo_method: Callable = gizmos[idx]
			gizmos_raw_data.append_array(gizmo_method.call())
		
		profile.set_gizmos_raw_data(gizmos_raw_data)
		all_raw_data.append_array(gizmos_raw_data)
	
	queue_redraw()



func _ready() -> void:
	
	clip_contents = true
	
	resized.connect(_on_resized)
	EditorServer.time_line2.layers_body.selected_changed.connect(_on_timeline_layers_body_selected_changed)
	EditorServer.properties.property_changed.connect(_on_properties_property_changed)
	PlaybackServer.position_changed.connect(_on_playback_server_position_changed)

func _draw() -> void:
	
	for raw_data: Dictionary in all_raw_data:
		
		var type: GizmoType = raw_data.type
		var args: Array = raw_data.args
		
		match type:
			GizmoType.GIZMO_TYPE_LINE: draw_line.callv(args)
			GizmoType.GIZMO_TYPE_RECT: draw_rect.callv(args)
			GizmoType.GIZMO_TYPE_CIRCLE: draw_circle.callv(args)


static func world2d_to_editor_viewport(point: Vector2) -> Vector2:
	var viewport_point: Vector2 = _canvas_transform * point
	return _offset + viewport_point * _scale_factor

#static func editor_viewport_to_world2d(point: Vector2) -> Vector2:
	#return point

func _on_resized() -> void:
	update_all_gizmos()

func _on_timeline_layers_body_selected_changed() -> void:
	_update_gizmos_profiles_by_selected_clips()
	update_all_gizmos()

func _on_properties_property_changed() -> void:
	update_all_gizmos()

func _on_playback_server_position_changed(position: int) -> void:
	_update_curr_gizmos_profiles_existent()
	update_all_gizmos()


class GizmosProfile extends RefCounted:
	
	@export var gizmos: Array[Callable]
	@export var modulate: Color = Color.WHITE
	@export var locked: bool = false
	
	var gizmos_raw_data: Array[Dictionary]
	
	func _back() -> int: return gizmos.size() - 1
	
	func get_gizmos() -> Array[Callable]: return gizmos
	func set_gizmos(new_val: Array[Callable]) -> void: gizmos = new_val
	
	func get_modulate() -> Color: return modulate
	func set_modulate(new_val: Color) -> void: modulate = new_val
	
	func get_locked() -> bool: return locked
	func set_locked(new_val: bool) -> void: locked
	
	func get_gizmos_raw_data() -> Array[Dictionary]: return gizmos_raw_data
	func set_gizmos_raw_data(new_val: Array[Dictionary]) -> void: gizmos_raw_data = new_val



