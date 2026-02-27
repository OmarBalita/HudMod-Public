shader_type canvas_item;

uniform float fov: hint_range(1., 179.) = 90.;
uniform bool cull_back = false;
uniform float y_rot: hint_range(-180., 180.) = .0;
uniform float x_rot: hint_range(-180., 180.) = .0;

varying flat vec2 o;
varying vec3 p;

void vertex() {
	float sin_b = sin(y_rot / 180. * PI);
	float cos_b = cos(y_rot / 180. * PI);
	float sin_c = sin(x_rot / 180. * PI);
	float cos_c = cos(x_rot / 180. * PI);
	
	mat3 inv_rot_mat;
	inv_rot_mat[0][0] = cos_b;
	inv_rot_mat[0][1] = .0;
	inv_rot_mat[0][2] = -sin_b;
	
	inv_rot_mat[1][0] = sin_b * sin_c;
	inv_rot_mat[1][1] = cos_c;
	inv_rot_mat[1][2] = cos_b * sin_c;
	
	inv_rot_mat[2][0] = sin_b * cos_c;
	inv_rot_mat[2][1] = -sin_c;
	inv_rot_mat[2][2] = cos_b * cos_c;
	
	
	float t = tan(fov / 360. * PI);
	p = inv_rot_mat * vec3((UV - .5), .5 / t);
	float v = (.5 / t) + .5;
	p.xy *= v * inv_rot_mat[2].z;
	o = v * inv_rot_mat[2].xy;
	
	VERTEX += (UV - .5) / TEXTURE_PIXEL_SIZE * t;
}

void fragment(){
	if (cull_back && p.z <= .0) discard;
	vec2 uv = (p.xy / p.z).xy - o;
	COLOR = texture(TEXTURE, uv + .5);
	COLOR.a *= step(max(abs(uv.x), abs(uv.y)), .5);
}