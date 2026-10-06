shader_type canvas_item;
render_mode unshaded;
uniform vec4 accent : source_color = vec4(0.2,0.8,0.5,1.0);
uniform vec4 secondary : source_color = vec4(0.2,0.8,0.5,1.0);
uniform float completion = -1.0;
float star_hash(vec2 cell) {
	return fract(sin(dot(cell,vec2(127.1,311.7)))*43758.5453);
}
void fragment() {
	vec2 p=UV;
	vec2 a=(p-vec2(-0.06,0.42))*vec2(1.35,1.15);
	vec2 b=(p-vec2(1.06,0.69))*vec2(1.35,1.1);
	float edge=1.0-smoothstep(0.0,0.48,min(p.x,1.0-p.x));
	float pulse=completion<0.0 ? 0.0 : smoothstep(0.25,1.1,completion)*(1.0-smoothstep(1.4,3.8,completion));
	vec3 glow=accent.rgb*exp(-dot(a,a)*3.0)+secondary.rgb*exp(-dot(b,b)*3.0);
	vec3 base=vec3(0.025,0.035,0.065);
	// Sparse, static distant lights; no moving particles behind the puzzle.
	vec2 grid=p*vec2(6.0,12.0);
	vec2 cell=floor(grid);
	float seed=star_hash(cell);
	vec2 star_position=vec2(star_hash(cell+17.3),star_hash(cell+43.7))*0.6+0.2;
	vec2 distance_px=(fract(grid)-star_position)*vec2(1.0,0.85);
	float star=(1.0-smoothstep(0.003,0.013,length(distance_px)))*step(0.78,seed);
	star*=0.035+edge*0.07;
	COLOR=vec4(base+glow*edge*(0.16+pulse*0.055)+vec3(0.72,0.82,1.0)*star,1.0);
}
