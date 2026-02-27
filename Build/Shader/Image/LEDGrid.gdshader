shader_type canvas_item;

uniform int grid_columns : hint_range(8, 256) = 64;
uniform int grid_rows : hint_range(8, 256) = 64;

uniform float led_brightness : hint_range(1.0, 5.0) = 2.5;
uniform float led_radius : hint_range(0.1, 0.8) = 0.4;
uniform float glow_size  : hint_range(0.0, 1.0) = 0.3;
uniform float glow_strength : hint_range(0.0, 1.0) = 0.5;
uniform float color_quantization : hint_range(0.0, 32.0) = 0.0;

uniform vec3 background_color : source_color = vec3(0.0, 0.0, 0.0);
uniform float background_opacity : hint_range(0.0,1.0) = 0.9;

uniform float glow_pulse : hint_range(0.0,1.0) = 0.0;
uniform float curvature : hint_range(0.0,0.2) = 0.05;
uniform bool enable_dither = true;
uniform bool enable_flicker = true;

void fragment() {
	vec2 centered = UV * 2.0 - 1.0;
	vec2 warped_uv = UV + centered * dot(centered, centered) * curvature;
	
	vec2 cell_count = vec2(float(grid_columns), float(grid_rows));
	vec2 cell_size = 1.0 / cell_count;
	
	vec2 grid_pos = floor(warped_uv / cell_size + 0.0001);
	vec2 cell_center = (grid_pos + 0.5) * cell_size;
	
	vec2 screen_uv_cell_center = UV + (cell_center - UV);
	vec4 sampled_color = texture(TEXTURE, screen_uv_cell_center);
	
	if (color_quantization > 0.0) {
	if (enable_dither) {
	vec2 noise = vec2(fract(sin(dot(UV.xy, vec2(12.9898,78.233)))*43758.5453));
	float dither = (noise.x + noise.y) * 0.5 / color_quantization;
	sampled_color.rgb = floor((sampled_color.rgb + dither) * color_quantization) / color_quantization;
	} else {
	sampled_color.rgb = round(sampled_color.rgb * color_quantization) / color_quantization;
	}
	}
	
	if (enable_flicker) {
	float flicker = 0.95 + 0.05 * sin(TIME * 6.283 + dot(grid_pos, vec2(13.37, 42.42)));
	sampled_color.rgb *= flicker;
	}
	
	vec2 cell_uv = fract(warped_uv / cell_size) - 0.5;
	float cell_aspect = cell_size.x / cell_size.y;
	cell_uv.x /= cell_aspect;
	
	float dist2 = dot(cell_uv, cell_uv);
	
	float r = led_radius * 0.5;
	float r_sq = r * r;
	float led_intensity = 1.0 - smoothstep(r_sq * 0.95, r_sq * 1.05, dist2);
	
	float glow_r = (led_radius + glow_size) * 0.5;
	float glow_r_sq = glow_r * glow_r;
	
	float lum = dot(sampled_color.rgb, vec3(0.299,0.587,0.114));
	float adaptive_glow = mix(0.2, 1.0, lum);
	
	float glow_intensity = (1.0 - smoothstep(r_sq, glow_r_sq, dist2)) * glow_strength * adaptive_glow;
	
	float pulse_multiplier = 1.0 + glow_pulse * 0.3;
	
	float total_intensity = max(led_intensity, glow_intensity) * pulse_multiplier;
	
	vec3 brightened_color = sampled_color.rgb * led_brightness;
	vec3 final_color = mix(background_color, brightened_color, total_intensity);
	float final_alpha = mix(background_opacity, sampled_color.a, total_intensity);
	
	COLOR = vec4(final_color, final_alpha);
}