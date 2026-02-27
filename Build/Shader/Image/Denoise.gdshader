shader_type canvas_item;

#include "res://Build/Shader/Global.gdshaderinc"

uniform float sigma: hint_range(.001, 5.) = 2.;
uniform float kSigma: hint_range(.001, 1.) = .1;
uniform float size: hint_range(1., 10.) = 3.;
uniform float sharpness: hint_range(.0, 10.) = .5;

void fragment() {
	vec2 tex_size = TEXTURE_PIXEL_SIZE;
	vec3 center_col = texture(TEXTURE, UV).rgb;
	
	float kernel_size = floor(size);
	float inv_sigma_sq = 1. / (2. * sigma * sigma);
	float inv_ksigma_sq = 1. / (2. * kSigma * kSigma);
	
	vec3 final_color = vec3(.0);
	float total_weight = .0;
	
	for (float i = -kernel_size; i <= kernel_size; ++i) {
		for (float j = -kernel_size; j <= kernel_size; ++j) {
			vec2 offset = vec2(i, j) * tex_size;
			vec3 sample_col = texture(TEXTURE, UV + offset).rgb;
			
			float dist_sq = i * i + j * j;
			float factor_spatial = exp(-dist_sq * inv_sigma_sq);
			
			float color_dist_sq = dot(sample_col - center_col, sample_col - center_col);
			float factor_color = exp(-color_dist_sq * inv_ksigma_sq);
			
			float weight = factor_spatial * factor_color;
			
			float sw = weight * (1. + sharpness * factor_spatial);
			
			total_weight += sw;
			final_color += sample_col * sw;
		}
	}
	
	COLOR.rgb = vec3(final_color / total_weight);
}