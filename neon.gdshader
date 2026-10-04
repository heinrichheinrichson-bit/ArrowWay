shader_type canvas_item;
render_mode unshaded;

uniform sampler2D path_points : filter_nearest, repeat_disable;
uniform int point_count = 2;
uniform vec4 neon_color : source_color = vec4(0.1, 1.0, 0.5, 1.0);
uniform vec2 tip;
uniform vec2 wing_a;
uniform vec2 wing_b;
uniform float emphasis = 0.0;
varying vec2 local_position;

void vertex() {
	local_position = VERTEX;
}

float segment_distance(vec2 p, vec2 a, vec2 b) {
	vec2 edge = b - a;
	float t = clamp(dot(p - a, edge) / max(dot(edge, edge), 0.000001), 0.0, 1.0);
	return length(p - a - edge * t);
}

float cross2(vec2 a, vec2 b) {
	return a.x * b.y - a.y * b.x;
}

float triangle_distance(vec2 p) {
	float distance = min(segment_distance(p, tip, wing_a), min(segment_distance(p, wing_a, wing_b), segment_distance(p, wing_b, tip)));
	float a = cross2(wing_a - tip, p - tip);
	float b = cross2(wing_b - wing_a, p - wing_a);
	float c = cross2(tip - wing_b, p - wing_b);
	bool inside = (a >= 0.0 && b >= 0.0 && c >= 0.0) || (a <= 0.0 && b <= 0.0 && c <= 0.0);
	return inside ? -distance : distance;
}

void fragment() {
	vec2 p = local_position;
	vec2 previous = texelFetch(path_points, ivec2(0, 0), 0).rg;
	float distance = 100000.0;
	for (int i = 1; i < point_count; i++) {
		vec2 current = texelFetch(path_points, ivec2(i, 0), 0).rg;
		distance = min(distance, segment_distance(p, previous, current));
		previous = current;
	}
	// One continuous silhouette: joints, round caps and arrowhead share one glow field.
	float shape = min(distance - 2.1, triangle_distance(p));
	float aa = max(fwidth(shape) * 0.6, 0.35);
	float fill = 1.0 - smoothstep(-aa, aa, shape);
	float outside = max(shape, 0.0);
	float glow = (0.30 + emphasis * 0.12) * exp(-outside / 2.25) + 0.06 * exp(-outside * outside / 65.0);
	float alpha = fill + (1.0 - fill) * glow;
	float core = smoothstep(0.5, 2.0, -shape);
	vec3 light = mix(neon_color.rgb, vec3(1.0), core * 0.24);
	COLOR = vec4(light, alpha * neon_color.a);
}
