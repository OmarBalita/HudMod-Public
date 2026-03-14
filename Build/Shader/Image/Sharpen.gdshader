shader_type canvas_item;

#include "res://Build/Shader/Global.gdshaderinc"

uniform float amount: hint_range(.0, 5.);
uniform float radius: hint_range(.1, 3.);
uniform float threshold: hint_range(.0, 1.);

void fragment() {
	vec2 texel_size = 1. / vec2(textureSize(TEXTURE, 0)) * radius;
	vec3 center_color = COLOR.rgb;
	
	float luma_c = get_luminance(center_color);
	float luma_t = get_luminance(texture(TEXTURE, UV + vec2(.0, -texel_size.y)).rgb);
	float luma_b = get_luminance(texture(TEXTURE, UV + vec2(.0, texel_size.y)).rgb);
	float luma_l = get_luminance(texture(TEXTURE, UV + vec2(-texel_size.x, .0)).rgb);
	float luma_r = get_luminance(texture(TEXTURE, UV + vec2(texel_size.x, .0)).rgb);
	
	float sharp = 4.0 * luma_c - (luma_t + luma_b + luma_l + luma_r);
	
	float mask = smoothstep(threshold, threshold + .2, abs(sharp));
	
	vec3 final_color = center_color + (sharp * amount * mask);
	
	COLOR.rgb = clamp(final_color, .0, 1.);
}
