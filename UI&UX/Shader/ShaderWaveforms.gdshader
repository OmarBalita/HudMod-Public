shader_type canvas_item;

uniform float pixelate_scale: hint_range(1., 8.) = 1.;
// One texel per waveform pixel (= one frame), R holds the linear gain. White (1.0) when unset.
uniform sampler2D gain_tex: hint_default_white, filter_nearest, repeat_disable;

void fragment() {
	vec2 size = vec2(textureSize(TEXTURE, 0));
	float pixel_uv = floor(UV.x * size.x / pixelate_scale) * pixelate_scale / size.x;

	float lod = log2(pixelate_scale);

	// Scale the bars around the center by the gain at this column.
	float gain = max(texture(gain_tex, vec2(pixel_uv, .5)).r, .0001);
	float y = .5 + (UV.y - .5) / gain;
	float inside = step(0., y) * step(y, 1.);

	COLOR.rgb = textureLod(TEXTURE, vec2(pixel_uv, clamp(y, 0., 1.)), lod).rgb;
	COLOR.a = min(1. - step(.001, COLOR.r), .5) * inside;
}
