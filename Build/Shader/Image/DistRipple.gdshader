shader_type canvas_item;

uniform float time;
uniform vec2 center = vec2(.0);
uniform float force: hint_range(-1., 1.) = .05;
uniform float size: hint_range(.0, 2.) = .5;
uniform float thickness: hint_range(.0, 1.) = .1;
uniform float speed: hint_range(.0, 100., .1) = 10.;

void fragment() {
	vec2 _center = center + vec2(.5);
	float ratio = TEXTURE_PIXEL_SIZE.x / TEXTURE_PIXEL_SIZE.y;
	float dist = distance(UV, _center);
	float mask = (1. - smoothstep(size - thickness, size, dist)) * smoothstep(size - thickness * 2., size - thickness, dist);
	float ripple = sin(dist * 50. - time * speed) * force * mask;
	vec2 distorted_uv = UV + normalize(UV - _center) * ripple;
	COLOR = texture(TEXTURE, distorted_uv);
}