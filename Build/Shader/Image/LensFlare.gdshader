shader_type canvas_item;
render_mode blend_mix;

#include "res://Build/Shader/Global.gdshaderinc"

uniform vec2 sun_position = vec2(.0);
uniform vec3 tint = vec3(1.4,1.2,1.);

void fragment()
{
	vec2 texResolution = 1. / TEXTURE_PIXEL_SIZE;
	vec2 resolution = 1. / SCREEN_PIXEL_SIZE;
	
	vec2 uv = FRAGCOORD.xy / resolution.xy - .5;
	uv.x *= resolution.x/resolution.y;
	vec2 mouse = (sun_position.xy / resolution.xy) - vec2(.5, .5);
	mouse.x *= resolution.x / resolution.y;
	
	vec4 previousColor = texture(TEXTURE, UV);
	
	vec3 color = previousColor.rgb;
	
	vec2 pos = mouse.xy;
	
	vec2 main = uv-pos;
	vec2 uvd = uv*(length(uv));
	
	float ang = atan(main.x,main.y);
	float dist = length(main);
	dist = pow(dist,.1);
	
	float f1 = max(.01-pow(length(uv+1.2*pos),1.9),.0)*7.;
	
	float f2 = max(1./(1.+32.*pow(length(uvd+.8*pos),2.)),.0)*.25;
	float f22 = max(1./(1.+32.*pow(length(uvd+.85*pos),2.)),.0)*.23;
	float f23 = max(1./(1.+32.*pow(length(uvd+.9*pos),2.)),.0)*.21;
	
	vec2 uvx = mix(uv,uvd,-.5);
	
	float f4 = max(.01-pow(length(uvx+.4*pos),2.4),.0)*6.;
	float f42 = max(.01-pow(length(uvx+.45*pos),2.4),.0)*5.;
	float f43 = max(.01-pow(length(uvx+.5*pos),2.4),.0)*3.;
	
	uvx = mix(uv,uvd,-.4);
	
	float f5 = max(.01-pow(length(uvx+.2*pos),5.5),.0)*2.;
	float f52 = max(.01-pow(length(uvx+.4*pos),5.5),.0)*2.;
	float f53 = max(.01-pow(length(uvx+.6*pos),5.5),.0)*2.;
	
	uvx = mix(uv,uvd,-0.5);
	
	float f6 = max(.01-pow(length(uvx-.3*pos),1.6),.0)*6.;
	float f62 = max(.01-pow(length(uvx-.325*pos),1.6),.0)*3.;
	float f63 = max(.01-pow(length(uvx-.35*pos),1.6),.0)*5.;
	
	vec3 c = vec3(.0);
	
	c.r+=f2+f4+f5+f6; c.g+=f22+f42+f52+f62; c.b+=f23+f43+f53+f63;
	c = c*1.3 - vec3(length(uvd)*.05);
	
	color += tint * c;
	
	color = apply_lum_desaturation(color,.5,.1);
	COLOR = vec4(color,1.);
}