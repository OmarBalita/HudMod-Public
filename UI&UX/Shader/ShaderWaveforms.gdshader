shader_type canvas_item;

uniform float pixelate_scale: hint_range(1., 8.) = 1.;

void fragment() {
	vec2 size = vec2(textureSize(TEXTURE, 0));
	float pixel_uv = floor(UV.x * size.x / pixelate_scale) * pixelate_scale / size.x;
	
	float lod = log2(pixelate_scale); 
	
	COLOR.rgb = textureLod(TEXTURE, vec2(pixel_uv, UV.y), lod).rgb;
	COLOR.a = min(1. - step(.001, COLOR.r), .5);
}