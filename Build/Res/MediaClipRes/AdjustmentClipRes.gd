class_name AdjustmentClipRes extends Display2DClipRes

var plane_mesh: QuadMesh = QuadMesh.new()

func init_node(root_layer_idx: int, layer_idx: int, layer_res: LayerRes, frame: int) -> Node:
	var mesh_instance: MeshInstance2D = MeshInstance2D.new()
	var size: int = maxi(ProjectServer2.project_res.resolution.x, ProjectServer2.project_res.resolution.y)
	plane_mesh.size = Vector2(size, size)
	mesh_instance.mesh = plane_mesh
	return _init_node2d(root_layer_idx, layer_idx, layer_res, frame, mesh_instance)

func _get_shader_fragment_snip() -> String:
	return "
	vec4 pixel_color = texture(SCREEN_TEXTURE, SCREEN_UV);
	color = pixel_color.rgb;
	alpha = pixel_color.a;
"
