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

@export var render_pass_margin: Vector2

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

func _get_exported_props() -> Dictionary[StringName, ExportInfo]:
	return {&"render_pass_margin": export(vec2_args(render_pass_margin))}

func get_pre_shader_material() -> ShaderMaterial:
	return pre_shader_material

func set_pre_shader_material(new_shader_material: ShaderMaterial) -> void:
	pre_shader_material = new_shader_material

func get_post_shader_material() -> ShaderMaterial:
	return post_shader_material

func set_post_shader_material(new_shader_material: ShaderMaterial) -> void:
	post_shader_material = new_shader_material

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
		
		curr_node.texture_scale = Vector2.ONE
		
		if ppr.is_in_process:
			await ppr.process_finished
			if mat_process_id != curr_mat_process_id:
				return
		await process_passes_materials(1.)

func process_passes_materials(render_scale: float) -> void:
	await ppr.request_process_output(get_self_main_texture(), ppsm, render_scale, render_pass_margin)

func get_self_main_texture() -> Texture2D: return null
func get_self_texture() -> Texture2D:
	return ppr.get_output_texture() if ppr else get_self_main_texture()

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
	build_shader_pipeline()
	super()

