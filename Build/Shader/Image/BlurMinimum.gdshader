shader_type canvas_item;

uniform float blur_amount : hint_range(.0, 500.) = 1.;
uniform bool circular = false;
uniform int quality : hint_range(1, 32) = 4;

void fragment() {
	
	float step_size = max(1., blur_amount / float(quality)); 
	
	vec4 min_color = vec4(1.);
	float blur_amount_sq = max(1., blur_amount * blur_amount);
	
	for (float x = -blur_amount; x <= blur_amount; x += step_size) {
		for (float y = -blur_amount; y <= blur_amount; y += step_size) {
			
			if (circular && (x*x + y*y > blur_amount_sq)) continue;
			
			vec2 offset = vec2(x, y) * TEXTURE_PIXEL_SIZE;
			vec4 curr_color = texture(TEXTURE, UV + offset);
			
			min_color = min(min_color, curr_color);
		}
	}
	
	COLOR = min_color;
}