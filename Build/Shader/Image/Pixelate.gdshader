shader_type canvas_item;

uniform int pixel_size: hint_range(1, 12800) = 32;

void fragment() {
	vec2 size = vec2(textureSize(TEXTURE, 0));
	vec2 pixelated_uv = round(UV * size / float(pixel_size)) * float(pixel_size) / size;
	COLOR = texture(TEXTURE, pixelated_uv);
}