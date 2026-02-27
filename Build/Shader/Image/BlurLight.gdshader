shader_type canvas_item;

uniform float rot_degrees = .0;
uniform float blur_amount: hint_range(.0, 1.) = .01;
uniform float weight: hint_range(.0, 1.) = .5;

void fragment() {
	vec4 color = texture(TEXTURE, UV);
	
	float angle2 = rot_degrees + PI / 2.;
	vec2 offset1 = vec2(cos(rot_degrees), sin(rot_degrees)) * blur_amount;
	vec2 offset2 = vec2(cos(angle2), sin(angle2)) * blur_amount;
	
	vec4 top = texture(TEXTURE, UV + offset1);
	vec4 down = texture(TEXTURE, UV - offset1);
	vec4 right = texture(TEXTURE, UV + offset2);
	vec4 left = texture(TEXTURE, UV - offset2);
	
	color += (top + down + right + left) * weight;
	color.rgb /= 1. + (4. * weight);
	
	COLOR = color;
}