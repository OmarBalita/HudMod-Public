#############################################################################
##  This file is part of: HudMod Video Editor                              ##
##  https://omar-top.itch.io/hudmod-video-editor                           ##
## ----------------------------------------------------------------------- ##
##  Copyright © 2026 Omar Mohammed Balita.                                 ##
## ----------------------------------------------------------------------- ##
## GPLv3                                                                   ##
#############################################################################
#@icon("res://Asset/Icons/Objects/particles-2d.png")
#class_name Particles2DClipRes extends Display2DClipRes
#
#enum MeshType {
	#RECTANGLE,
	#CIRCLE,
	#CAPSULE
#}
#
#@export_range(1, 10_000_000) var amount: int = 24
#@export var mesh_type: MeshType
#
#@export_group(&"Mesh Properties")
#@export var size: Vector2
#@export var radius: float = .5
#@export var height: float = 1.
#@export var rings: int = 16
#@export var texture: String
#
#var multimesh: MultiMesh
#
#var particles_comps: Array = get_section_comps_absolute(&"Particles")
#
#static func get_media_clip_info() -> Dictionary[StringName, String]:
	#return {
	#&"title": "Particles2D",
	#&"description": ""
#}
#
#func _init() -> void:
	#multimesh = MultiMesh.new()
	#_update_multimesh()
#
#func _update_multimesh() -> void:
	#multimesh.instance_count = amount
	#
	#var mesh: Mesh
	#match mesh_type:
		#0:
			#mesh = QuadMesh.new()
			#mesh.size = size
		#1:
			#mesh = SphereMesh.new()
			#_update_sphere_mesh(mesh)
		#2:
			#mesh = CapsuleMesh.new()
			#_update_sphere_mesh(mesh)
#
#func _update_sphere_mesh(mesh: Mesh) -> void:
	#mesh.radius = radius
	#mesh.height = height
	#mesh.radial_segments = 4
	#mesh.rings = rings
#
#func _get_exported_props() -> Dictionary[StringName, ExportInfo]:
	#var get_type: Callable = get.bind(&"mesh_type")
	#var rect_cond: Array = [get_type, [0]]
	#var sphere_cond: Array = [get_type, [1, 2]]
	#return {
		#&"amount": export(int_args(amount, 1, 10_000_000)),
		#&"mesh_type": export(options_args(mesh_type, MeshType)),
		#&"Mesh Properties": export_method(ExportMethodType.METHOD_ENTER_CATEGORY),
		#&"size": export(vec2_args(size), rect_cond),
		#&"radius": export(float_args(radius, .001), sphere_cond),
		#&"height": export(float_args(height, .001), sphere_cond),
		#&"rings": export(int_args(rings, 1), sphere_cond),
		#&"texture": export(string_args(texture)),
		#&"_Mesh Properties": export_method(ExportMethodType.METHOD_EXIT_CATEGORY)
	#}
#
#func init_node(layer_idx: int, frame_in: int) -> Node:
	#var particles:= Particles2D.new()
	#return particles

