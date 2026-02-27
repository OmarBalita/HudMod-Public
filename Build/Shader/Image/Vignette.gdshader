shader_type canvas_item;

#include "res://Build/Shader/Global.gdshaderinc"

uniform float intensity: hint_range(.0, 5.) = .75;
uniform float smoothness: hint_range(.0, 1.) = .3;
uniform float roundness: hint_range(.0, 1.) = .4;
uniform float chromatic_aberration: hint_range(.0, .05) = .01;
uniform vec4 vignette_color: source_color = vec4(.0, .0, .0, 1.);
uniform sampler2D vignette_texture: hint_default_black;
uniform float texture_opacity: hint_range(.0, 1.) = .0;

void fragment() {
	vec2 center_dist = abs(UV - .5) * intensity;
	float dist = pow(dot(center_dist, center_dist), roundness);
	float vignette = smoothstep(.5 - smoothness, .5 + smoothness, dist);
	
	vec4 tex_vignette = 1. - texture(vignette_texture, UV);
	
	float final_vignette = mix(vignette, vignette * get_luminance(tex_vignette.rgb), texture_opacity);
	
	float r = texture(TEXTURE, UV + (final_vignette * chromatic_aberration)).r;
	float g = texture(TEXTURE, UV).g;
	float b = texture(TEXTURE, UV - (final_vignette * chromatic_aberration)).b;
	
	vec4 scene_color = vec4(r, g, b, 1.);
	
	COLOR = mix(scene_color, vignette_color, final_vignette);
}