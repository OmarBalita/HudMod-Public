shader_type canvas_item;

#include "res://Build/Shader/Global.gdshaderinc"

uniform vec2 light_dir = vec2(1., .0);
uniform float intensity: hint_range(.0, .02) = .005;
uniform vec4 highlight_color: source_color = vec4(1., 1., 1., 1.);
uniform vec4 shadow_color: source_color = vec4(.0, .0, .0, 1.);

void fragment() {
	vec4 color = texture(TEXTURE, UV);
	
	vec2 dir = normalize(light_dir) * intensity;
	
	float sample_plus = get_luminance(texture(TEXTURE, UV + dir).rgb);
	float sample_minus = get_luminance(texture(TEXTURE, UV - dir).rgb);
	
	float diff = sample_plus - sample_minus;
	
	vec4 base = color;
	vec4 final = base;
	
	if (diff > .0) {
		final = mix(final, highlight_color, clamp(diff * 5., .0, 1.));
	} else {
		final = mix(final, shadow_color, clamp(abs(diff) * 5., .0, 1.));
	}
	
	COLOR = final;
}