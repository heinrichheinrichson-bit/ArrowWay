vec3 atmosphere_color(vec2 p, vec3 tint, float phase) {

	vec3 base = mix(vec3(0.018, 0.026, 0.057), vec3(0.035, 0.046, 0.084), p.y);
	vec2 a = (p-vec2(0.95,0.30+sin(phase)*0.08))*vec2(1.3,1.5);
	vec2 b = (p-vec2(-0.12,0.68+cos(phase)*0.08))*vec2(1.5,1.1);
	vec2 c = (p-vec2(0.55,1.05))*vec2(1.1,1.8);
	base += tint*exp(-dot(a,a)*3.8)*0.20;
	base += vec3(0.42,0.24,0.72)*exp(-dot(b,b)*3.2)*0.20;
	base += vec3(0.12,0.48,0.60)*exp(-dot(c,c)*4.0)*0.095;
	float ribbon_distance = (p.x-0.48-sin(p.y*4.8+phase*0.4)*0.32)*9.0;
	float ribbon = exp(-ribbon_distance*ribbon_distance);
	base += tint*ribbon*0.018;
	return base;
}
