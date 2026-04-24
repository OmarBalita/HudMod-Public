class_name CompFade extends InOutComponentRes

const MODULATE: String = &"modulate"

func _inout(frame: int) -> void:
	var sm: ShaderMaterial = owner.get_post_shader_material()
	var ci: CompCanvasItem = owner.get_section_comps_absolute(&"Display2D")[0]
	
	var codename: StringName = ci.get_shader_param_code_name(MODULATE)
	var mod: Color = sm.get_shader_parameter(codename)
	
	sm.set_shader_parameter(codename, mod * t_ratio)

