shader_type canvas_item;

uniform vec2 center = vec2(.0);
uniform float rotation: hint_range(-10., 10.) = 3.;
uniform float radius: hint_range(.0, 1.) = .5;

void fragment() {
	vec2 _center = center + vec2(.5);
	vec2 uv = UV - _center;
	float dist = length(uv);
	
	if (dist < radius) {
		float percent = (radius - dist) / radius;
		float angle = percent * percent * rotation;
		
		float s = sin(angle);
		float c = cos(angle);
		mat2 rotation_matrix = mat2(vec2(c, -s), vec2(s, c));
		
		uv = rotation_matrix * uv;
	}
	
	uv += _center;
	
	COLOR = texture(TEXTURE, uv);
}