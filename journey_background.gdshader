shader_type canvas_item;
render_mode unshaded;
uniform vec4 accent : source_color = vec4(0.2, 0.8, 0.7, 1.0);
void fragment() {
	vec2 p = UV;
	vec3 base = mix(vec3(0.019, 0.034, 0.062), vec3(0.029, 0.047, 0.083), p.y);
	float mist = exp(-dot((p - vec2(0.82, 0.22)) * vec2(1.8, 1.2), (p - vec2(0.82, 0.22)) * vec2(1.8, 1.2)) * 5.0);
	float violet = exp(-dot((p - vec2(0.02, 0.76)) * vec2(1.6, 1.4), (p - vec2(0.02, 0.76)) * vec2(1.6, 1.4)) * 5.0);
	base += accent.rgb * mist * 0.075 + vec3(0.40, 0.22, 0.65) * violet * 0.055;
	COLOR = vec4(base, 1.0);
}
