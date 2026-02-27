shader_type canvas_item;

#include "res://Build/Shader/Global.gdshaderinc"

uniform float line_thickness: hint_range(.0, 50.) = 4.;
uniform float sensitivity: hint_range(.0, 1.) = .2;
uniform vec4 line_color: source_color = vec4(.0, .0, .0, 1.);

void fragment() {
	vec2 size = vec2(textureSize(TEXTURE, 0));
	float x = line_thickness / size.x;
	float y = line_thickness / size.y;
	
	vec3 center = texture(TEXTURE, UV).rgb;
	vec3 left = texture(TEXTURE, UV + vec2(-x, .0)).rgb;
	vec3 right = texture(TEXTURE, UV + vec2(x, .0)).rgb;
	vec3 top = texture(TEXTURE, UV + vec2(.0, -y)).rgb;
	vec3 bottom = texture(TEXTURE, UV + vec2(.0, y)).rgb;
	
	float b_center = get_brightness(center);
	float diff = .0;
	diff += abs(b_center - get_brightness(left));
	diff += abs(b_center - get_brightness(right));
	diff += abs(b_center - get_brightness(top));
	diff += abs(b_center - get_brightness(bottom));
	
	if (diff > sensitivity) {
		COLOR = line_color;
	}
}