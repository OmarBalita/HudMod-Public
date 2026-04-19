shader_type canvas_item;

uniform bool flip;
uniform vec3 color: source_color = vec3(.0);

void fragment() {
	float line = flip ? UV.y : 1. - UV.y;
	float smooth_alpha = smoothstep(.0, 1., line);
	COLOR = vec4(color.r, color.g, color.b, smooth_alpha);
}