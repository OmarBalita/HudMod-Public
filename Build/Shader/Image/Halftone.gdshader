shader_type canvas_item;

#include "res://Build/Shader/Global.gdshaderinc"

uniform vec2 offset;
uniform float size = 64.;
uniform float value_multiplier: hint_range(.0, 32.) = .6;
uniform vec4 dot_color: source_color = vec4(1.);
uniform vec4 back_color: source_color = vec4(.0, .0, .0, 1.);

void fragment() {
	vec2 _offset = offset * .01;
	
	vec2 ratio = vec2(1., TEXTURE_PIXEL_SIZE.x / TEXTURE_PIXEL_SIZE.y);
	
	vec2 offset_uv = UV + _offset;
	vec2 pixelated_uv = floor(offset_uv * size * ratio) / (size * ratio);
	
	float dots = length(fract(offset_uv * size * ratio) - vec2(.5)) * 2.;
	
	float value = rgb2hsv(texture(TEXTURE, pixelated_uv - _offset).rgb).z;
	
	dots += value * value_multiplier;
	dots = pow(dots, 5.);
	dots = clamp(dots, .0, 1.);
	
	vec4 final_color = mix(dot_color, back_color, dots);
	
	COLOR.rgb = final_color.rgb;
	COLOR.a = texture(TEXTURE, UV).a * final_color.a;
}