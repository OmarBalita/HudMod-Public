class_name MeshRes extends UsableRes

static var mesh_types: Array = [PlaneMesh, BoxMesh, SphereMesh, CapsuleMesh, CylinderMesh, TorusMesh, ArrayMesh]

enum MeshTypes {
	TYPE_PLANE_MESH,
	TYPE_BOX_MESH,
	TYPE_SPHERE_MESH,
	TYPE_CAPSULE_MESH,
	TYPE_CYLENDER_MESH,
	TYPE_TORUS_MESH,
	TYPE_ARRAY_MESH
}


@export_group("Properties")
@export_range(0, 1e10) var subdv_depth: int
@export_range(0, 1e10) var subdv_width: int
@export_range(0, 1e10) var subdv_height: int

@export_subgroup("Plane Mesh")
@export var plane_size: Vector2

@export_subgroup("Box Mesh")
@export var box_size: Vector3

@export_subgroup("Sphere Capsule Cylinder Torus Mesh")
@export var height: float
@export var is_hemisphere: bool
@export var radial_segments: int
@export var radius: float
@export var rings: int

@export_subgroup("Cylinder Mesh")
@export var bottom_radius: float
@export var top_radius: float
@export var cap_bottom: bool
@export var cap_top: bool

@export_subgroup("Torus Mesh")
@export var inner_radius: float
@export var outer_radius: float
@export var ring_segments: int


@export var _mesh: Mesh = _get_mesh_from_type(1):
	set(val):
		if val:
			var mesh_type = _get_type_from_mesh(val)
			if mesh_type != null:
				_mesh = val

func _init() -> void:
	set_res_id("MeshRes")

func _get_mesh() -> Mesh:
	return _mesh

func _set_mesh(new_mesh: Mesh) -> void:
	_mesh = new_mesh

func get_surface_count() -> int:
	return _mesh.get_surface_count()

func create_outline(margin: float) -> MeshRes:
	var outlined_mesh = _mesh.create_outline(margin)
	return _new_from_mesh(outlined_mesh)

static func _get_type_from_mesh(mesh: Mesh) -> Variant:
	for mesh_type in mesh_types:
		if typeof(mesh) == mesh_type:
			return mesh_type
	return null

static func _get_mesh_from_type(type: int = 0) -> Variant:
	if type <= mesh_types.size() - 1:
		return mesh_types[type]
	return null

static func _new_from_mesh(mesh: Mesh) -> MeshRes:
	var res = MeshRes.new()
	res.mesh = mesh
	return res




