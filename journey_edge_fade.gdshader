shader_type canvas_item;
render_mode unshaded;
uniform vec4 accent : source_color = vec4(0.2,0.8,0.7,1.0);
uniform bool lower = false;
void fragment() {
	vec2 p = SCREEN_UV;
	vec3 base = mix(vec3(0.019,0.034,0.062),vec3(0.029,0.047,0.083),p.y);
	vec2 a = (p-vec2(0.82,0.22))*vec2(1.8,1.2);
	vec2 b = (p-vec2(0.02,0.76))*vec2(1.6,1.4);
	base += accent.rgb*exp(-dot(a,a)*5.0)*0.075 + vec3(0.40,0.22,0.65)*exp(-dot(b,b)*5.0)*0.055;
	float opacity = smoothstep(0.0,1.0,UV.y);
	COLOR = vec4(base,lower ? opacity : 1.0-opacity);
}
