shader_type canvas_item;
render_mode unshaded;
uniform vec4 accent : source_color = vec4(0.2,0.8,0.5,1.0);
uniform vec4 secondary : source_color = vec4(0.2,0.8,0.5,1.0);
uniform float completion = -1.0;
void fragment() {
	vec2 p=UV;
	vec2 a=(p-vec2(-0.15,0.42))*vec2(1.5,1.25);
	vec2 b=(p-vec2(1.15,0.69))*vec2(1.5,1.2);
	float edge=1.0-smoothstep(0.0,0.42,min(p.x,1.0-p.x));
	float pulse=completion<0.0 ? 0.0 : smoothstep(0.25,1.1,completion)*(1.0-smoothstep(1.4,3.8,completion));
	vec3 glow=accent.rgb*exp(-dot(a,a)*3.0)+secondary.rgb*exp(-dot(b,b)*3.0);
	vec3 base=vec3(0.025,0.035,0.065);
	COLOR=vec4(base+glow*edge*(0.09+pulse*0.055),1.0);
}
