@icon("res://Asset/Icons/Objects/empty-object-2d.png")
class_name Display2DClipRes extends MediaClipRes

signal shader_code_compiled_successfully()
signal shader_material_changed()

@export var position: Vector2 = Vector2.ZERO
@export var rotation_degrees: float = .0
@export var scale: Vector2 = Vector2.ONE
@export var skew: float

@export var render_pass_margin: Vector2

var shader_code: String:
	set(val):
		shader_code = val
		await EditorServer.get_tree().process_frame
		
		if shader_code.is_empty():
			shader_material = null
		else:
			shader_code_compiled_successfully.emit()
			var new_shader_material:= ShaderMaterial.new()
			var new_shader:= Shader.new()
			new_shader.set_code(shader_code)
			new_shader_material.set_shader(new_shader)
			shader_material = new_shader_material

var shader_material: ShaderMaterial: set = _set_shader_material

var ppsm: Array[ShaderMaterial] # Ping-Pong ShaderMaterials.
var ppr: PingPongRenderer

var mat_process_id: int

static func get_explorer_section() -> StringName: return &"Object2D"
static func get_properties_section() -> StringName: return &"Display2D"
static func get_media_clip_info() -> Dictionary[StringName, String]:
	return {
		&"title": "Object2D",
		&"Description": ""
	}

func _set_shader_material(val: ShaderMaterial) -> void:
	shader_material = val
	
	if shader_material:
		for section_key: StringName in components:
			for comp_res: ComponentRes in components[section_key]:
				if comp_res is ShaderComponentRes and comp_res.enabled:
					comp_res._ready_shader()
	
	shared_data_clear()
	if curr_node:
		await curr_node.get_tree().process_frame
		curr_node.material = shader_material
		process_here()
	
	shader_material_changed.emit()


func _get_exported_props() -> Dictionary[StringName, ExportInfo]:
	return {
		&"Transform": export_method(ExportMethodType.METHOD_ENTER_CATEGORY),
		&"position": export(vec2_args(position)),
		&"rotation_degrees": export(float_args(rotation_degrees)),
		&"scale": export(vec2_args(scale)),
		&"skew": export(float_args(skew)),
		&"_Transform": export_method(ExportMethodType.METHOD_EXIT_CATEGORY),
		&"render_pass_margin": export(vec2_args(render_pass_margin)),
	}

func get_shader_code() -> String:
	return shader_code

func set_shader_code(new_shader_code: String) -> void:
	shader_code = new_shader_code

func get_shader_material() -> ShaderMaterial:
	return shader_material

func set_shader_material(new_shader_material: ShaderMaterial) -> void:
	shader_material = new_shader_material

func init_node(layer_idx: int, frame_in: int) -> Node:
	return Node2D.new()

func enter(node: Node) -> void:
	curr_node.material = shader_material
	if not ppsm.is_empty():
		ppr = RenderFarm.pingpong_renderer_init(self)
	super(node)

func _process_comps(frame: int) -> void:
	add_stacked_value(&"position", position)
	add_stacked_value(&"rotation_degrees", rotation_degrees)
	add_stacked_value(&"scale", scale)
	add_stacked_value(&"skew", skew)
	super(frame)

func _after_process_comps(frame: int) -> void:
	if shader_material:
		await process_material(frame)
	super(frame)

func exit(node: Node) -> void:
	super(node)
	if ppr: RenderFarm.pingpong_renderer_free(self)


func process_material(frame: int) -> void:
	var frame_f: float = float(frame)
	
	mat_process_id += 1
	var curr_mat_process_id: int = mat_process_id
	
	if ppsm:
		for sm: ShaderMaterial in ppsm:
			sm.set_shader_parameter(&"time", frame_f)
		
		var render_scale: float = EditorServer.editor_settings.viewport_effect_ratio
		add_stacked_value(&"scale", render_scale, ComponentRes.MethodType.DIVIDE)
		
		if ppr.is_in_process:
			await ppr.process_finished
			if mat_process_id != curr_mat_process_id:
				return
		await process_passes_materials(render_scale)
	
	if mat_process_id == curr_mat_process_id:
		shader_material.set_shader_parameter(&"time", frame_f)

func process_passes_materials(render_scale: float) -> void:
	var output: Texture2D = await ppr.request_process_output(get_self_main_texture(), ppsm, render_scale, render_pass_margin)
	if output:
		curr_node.texture = output

func get_self_main_texture() -> Texture2D: return null

func build_shader_pipeline() -> void:
	
	ppsm.clear()
	
	var used_names: PackedStringArray
	var global_params_section: String = "\n" + _format_shader_snip(_get_shader_global_param_snip(), {}, used_names, true)
	var fragment_section: String = "\n" + _format_shader_snip(_get_shader_fragment_snip(), {}, used_names, false)
	var vertex_section: String = "\n" + _format_shader_snip(_get_shader_vertex_snip(), {}, used_names, false)
	
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
				
				if global_params_snip: global_params_section += "\n" + global_params_snip
				if fragment_snip: fragment_section += "\n" + fragment_snip
				if vertex_snip: vertex_section += "\n" + vertex_snip
				
				comp_res.set_shader_params_names_list(params_names_list)
	
	if Scene2.has_object(self):
		var has_passes: bool = not ppsm.is_empty()
		
		if ppr:
			if not has_passes:
				RenderFarm.pingpong_renderer_free(self)
				curr_node.texture = get_self_main_texture()
		
		elif has_passes:
			ppr = RenderFarm.pingpong_renderer_init(self)
	
	if global_params_section.is_empty() and fragment_section.is_empty() and vertex_section.is_empty():
		return
	
	fragment_section = _get_shader_fragment(fragment_section)
	vertex_section = _get_shader_vertex(vertex_section)
	shader_code = str(
		_get_shader_header(), "\n",
		"\nuniform float time;",
		global_params_section, "\n",
		fragment_section, "\n",
		vertex_section
	)

func _get_shader_header() -> String:
	return "shader_type canvas_item;\n#include \"res://Build/Shader/Global.gdshaderinc\"\n"

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

func _get_shader_global_param_snip() -> String: return ""
func _get_shader_fragment_snip() -> String: return ""
func _get_shader_vertex_snip() -> String: return ""



static func _format_shader_snip(shader_snip: String, params_names_list: Dictionary[String, String], used_names: PackedStringArray, is_global: bool) -> String:
	var gen_id_func: Callable = ProjectServer.generate_new_id.bind(used_names, 12, true)
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


func _emit_media_clip_res_updated(_from: int = -1, _length: int = -1) -> void:
	build_shader_pipeline()
	super(_from, _length)



