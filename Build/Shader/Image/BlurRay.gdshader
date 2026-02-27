shader_type canvas_item;

uniform vec2 center = vec2(.0);
uniform float power: hint_range(.0, 1.) = .2;
uniform int quality: hint_range(1, 64) = 12;
uniform float edge_scale: hint_range(.0, 1.) = .8;

void fragment()
{
	vec2 direction = UV - (center + vec2(.5));
	vec4 c = vec4(.0);
	float f = 1. / float(quality);
	
	for (int i = 0; i < quality; i++) {
		c += texture(TEXTURE, UV - power / float(quality) * direction * float(i)) * f;
	}
	
	float mix_val = smoothstep(.0, 1. - edge_scale, distance((center + vec2(.5)), UV));
	vec4 result = mix(texture(TEXTURE, UV), c, mix_val);
	COLOR = result;
}

