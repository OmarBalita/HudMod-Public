shader_type canvas_item;

uniform float blur_amount: hint_range(.0, 500.) = 1.;
uniform bool circular = false;
uniform int quality: hint_range(1, 32) = 4;

void fragment() {
	vec2 ps = TEXTURE_PIXEL_SIZE;
	
	float step_size = max(1., blur_amount / float(quality)); 
	
	vec4 max_color = vec4(.0);
	float blur_amount_sq = max(1., blur_amount * blur_amount);
	
	for (float x = -blur_amount; x <= blur_amount; x += step_size) {
		for (float y = -blur_amount; y <= blur_amount; y += step_size) {
			
			if (circular && (x*x + y*y > blur_amount_sq)) continue;
			
			vec2 offset = vec2(x, y) * ps;
			vec4 curr_color = texture(TEXTURE, UV + offset);
			
			max_color = max(max_color, curr_color);
		}
	}
	
	COLOR = max_color;
}