shader_type canvas_item;

uniform float size = 32.;
uniform float randomness = 1.;

void fragment() {
	float ratio = TEXTURE_PIXEL_SIZE.y / TEXTURE_PIXEL_SIZE.x;
	
	vec2 cell_size = vec2(max(size, 0.01) * ratio, max(size, 0.01));
	vec2 _size = 1. / cell_size; 
	
	vec2 uv = UV;
	vec2 grid_uv = uv / _size;
	vec2 cell_index = floor(grid_uv);
	vec2 cell_fract = fract(grid_uv);
	
	float min_dist = 2.;
	vec2 closest_cell_offset;
	
	for (int y = -1; y <= 1; y++) {
		for (int x = -1; x <= 1; x++) {
			vec2 neighbor = vec2(float(x), float(y));
			vec2 curr_uv = cell_index + neighbor;
			vec2 point = fract(
				sin(
					vec2(
						dot(curr_uv, vec2(127.1, 311.7)),
						dot(curr_uv, vec2(269.5, 183.3))
					)
			) * 43758.5453);
			
			point = .5 + .5 * sin(TIME * 0. + point * 6.2831);
			
			point = mix(vec2(.5), point, randomness);
			
			vec2 diff = neighbor + point - cell_fract;
			float dist = length(diff);
			
			if (dist < min_dist) {
				min_dist = dist;
				closest_cell_offset = neighbor + point;
			}
		}
	}
	
	vec2 target_uv = (cell_index + closest_cell_offset) * _size;
	
	vec4 color = texture(TEXTURE, target_uv);
	
	COLOR = color;
}