shader_type canvas_item;

uniform float force: hint_range(-5., 5.) = .2;
uniform float zoom: hint_range(-2., 2.) = 1.;

void fragment() {
	vec2 p = UV * 2. - 1.;
	float r2 = dot(p, p);
	float f = 1. + force * r2;
	p *= f / (1. + force * zoom);
	vec2 final_uv = (p + 1.) / 2.;
	vec4 color = texture(TEXTURE, final_uv);
	if (final_uv.x < .0 || final_uv.x > 1. || final_uv.y < .0 || final_uv.y > 1.) {
		color = vec4(.0, .0, .0, 1.);
	}
	COLOR = color;
}