shader_type canvas_item;

#include "res://Build/Shader/Global.gdshaderinc"

uniform float levels: hint_range(2., 1024.) = 256.;
uniform bool use_gradient = true;
uniform sampler2D gradient: hint_default_black;

uniform float filter_radius: hint_range(.0, 50.) = 5.;
uniform float filter_quality: hint_range(.1, 1.) = .2;

void fragment() {
	vec2 tex_size = vec2(textureSize(TEXTURE, 0));
	vec2 pixel_size = 1. / tex_size;
	
	vec3 accumulated_color = vec3(.0);
	float total_weights = .0;
	
	float step_size = 1. / max(filter_quality, .01);
	
	for (float x = -filter_radius; x <= filter_radius; x += step_size) {
		for (float y = -filter_radius; y <= filter_radius; y += step_size) {
			vec2 offset = vec2(x, y) * pixel_size;
			accumulated_color += texture(TEXTURE, UV + offset).rgb;
			total_weights += 1.;
		}
	}
	
	vec3 smooth_col = (total_weights > .0) ? (accumulated_color / total_weights) : texture(TEXTURE, UV).rgb;
	
	float luma = get_luminance(smooth_col);
	float v = luma * (levels - 1.);
	float delta = fwidth(v);
	
	vec3 final_result;
	if (use_gradient) {
		float posterized_luma = (floor(v) + smoothstep(.5 - delta, .5 + delta, fract(v))) / (levels - 1.);
		final_result = texture(gradient, vec2(posterized_luma, .0)).rgb;
	} else {
		vec3 v_rgb = smooth_col.rgb * (levels - 1.);
		vec3 delta_rgb = fwidth(v_rgb);
		final_result = (floor(v_rgb) + smoothstep(vec3(.5) - delta_rgb, vec3(.5) + delta_rgb, fract(v_rgb))) / (levels - 1.);
	}
	
	COLOR = vec4(final_result, texture(TEXTURE, UV).a);
}