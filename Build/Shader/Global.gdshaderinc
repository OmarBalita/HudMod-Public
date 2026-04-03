
vec3 rgb2hsv(vec3 tex) {
	vec3 hsv;
	vec3 c = tex;
	vec4 K = vec4(.0, -1. / 3., 2. / 3., -1.);
	vec4 p = mix(vec4(c.bg, K.wz), vec4(c.gb, K.xy), step(c.b, c.g));
	vec4 q = mix(vec4(p.xyw, c.r), vec4(c.r, p.yzx), step(p.x, c.r));
	float d = q.x - min(q.w, q.y);
	float e = 1.e-10;
	return vec3(abs(q.z + (q.w - q.y) / (6. * d + e)), d / (q.x + e), q.x);
}

vec3 apply_lum_desaturation(vec3 color, float factor,float factor2)
{
	float w = color.x+color.y+color.z;
	return mix(color,vec3(w)*factor,w*factor2);
}

vec3 apply_hue(vec3 c, float h) {
	vec3 k = vec3(.57735);
	float cosAngle = cos(h * 6.28318);
	return c * cosAngle + cross(k, c) * sin(h * 6.28318) + k * dot(k, c) * (1. - cosAngle);
}

vec3 apply_sat(vec3 c, float s) {
	float luma = dot(c, vec3(.2126, .7152, .0722));
	return luma + s * (c - luma);
}

vec3 apply_vibrance(vec3 c, float v) {
	float max_color = max(c.r, max(c.g, c.b));
	float avg_color = (c.r + c.g + c.b) / 3.;
	float amt = (abs(max_color - avg_color) * 2.) * -v;
	return mix(c, vec3(max_color), amt);
}

float inside_unit_square(vec2 v) {
	vec2 s = step(vec2(0.0), v) - step(vec2(1.0), v);
	return s.x * s.y;
}

vec2 rotate(vec2 uv, vec2 p, float angle)
{
	mat2 rotation = mat2(vec2(cos(angle), -sin(angle)),
	vec2(sin(angle), cos(angle)));
	uv -= p;
	uv = uv * rotation;
	uv += p;
	return uv;
}

float get_brightness(vec3 color) {
	return (color.r + color.g + color.b) / 3.;
}

float get_luminance(vec3 color) {
	return dot(color, vec3(.2126, .7152, .0722));
}

float normpdf3(vec3 v, float s) {
	return exp(-0.5 * dot(v, v) / (s * s));
}

float random(vec2 uv) {
	return fract(sin(dot(uv, vec2(12.9898, 78.233))) * 43758.5453);
}


float overlay(float base, float blend) {
	return base < 0.5 ? (2.0 * base * blend) : (1.0 - 2.0 * (1.0 - base) * (1.0 - blend));
}

float soft_light(float base, float blend) {
	return blend < 0.5 ? 
		(2.0 * base * blend + base * base * (1.0 - 2.0 * blend)) : 
		(sqrt(base) * (2.0 * blend - 1.0) + 2.0 * base * (1.0 - blend));
}

float color_dodge(float base, float blend) {
	return blend == 1.0 ? blend : min(1.0, base / (1.0 - blend));
}

float color_burn(float base, float blend) {
	return blend == 0.0 ? blend : max(0.0, 1.0 - (1.0 - base) / blend);
}

float vivid_light(float base, float blend) {
	return blend < 0.5 ? color_burn(base, 2.0 * blend) : color_dodge(base, 2.0 * (blend - 0.5));
}
