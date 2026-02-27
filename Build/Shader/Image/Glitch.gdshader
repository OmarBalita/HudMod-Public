shader_type canvas_item;

uniform float time;
uniform float power = 0.03;
uniform float rate : hint_range( 0.0, 1.0 ) = 0.2;
uniform float speed = 5.0;
uniform float block_size = 30.5;
uniform float color_rate : hint_range( 0.0, 1.0 ) = 0.01;

float random( float seed )
{
	return fract( 543.2543 * sin( dot( vec2( seed, seed ), vec2( 3525.46, -54.3415 ) ) ) );
}

void fragment( )
{
	float enable_shift = float(
		random( trunc( time * speed ) )
	<	rate
	);
	
	vec2 fixed_uv = UV;
	fixed_uv.x += (
		random(
			( trunc( UV.y * block_size ) / block_size )
		+	time
		) - 0.5
	) * power * enable_shift;
	
	vec4 pixel_color = textureLod( TEXTURE, fixed_uv, 0.0 );
	pixel_color.r = mix(
		pixel_color.r
	,	textureLod( TEXTURE, fixed_uv + vec2( color_rate, 0.0 ), 0.0 ).r
	,	enable_shift
	);
	pixel_color.b = mix(
		pixel_color.b
	,	textureLod( TEXTURE, fixed_uv + vec2( -color_rate, 0.0 ), 0.0 ).b
	,	enable_shift
	);
	COLOR = pixel_color;
}
