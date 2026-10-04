shader_type canvas_item;
uniform float selection_opacity = 1.0;
uniform float completion_time = -1.0;
uniform float origin_y = 0.0;
render_mode unshaded;

uniform sampler2D path_points : filter_nearest, repeat_disable;
uniform int point_count = 2;
uniform vec4 neon_color : source_color = vec4(0.1, 1.0, 0.5, 1.0);
uniform vec2 tip;
uniform vec2 wing_a;
uniform vec2 wing_b;
uniform float emphasis = 0.0;
uniform bool gradient_enabled = false;
uniform sampler2D color_lookup : source_color, filter_linear, repeat_disable;
uniform float color_length = 1.0;
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
	float walked = 0.0;
	float color_distance = 0.0;
	for (int i = 1; i < point_count; i++) {
		vec2 current = texelFetch(path_points, ivec2(i, 0), 0).rg;
		vec2 edge = current - previous;
		float edge_length = gradient_enabled ? length(edge) : 0.0;
		float projection = clamp(dot(p - previous, edge) / max(dot(edge, edge), 0.000001), 0.0, 1.0);
		float candidate = length(p - previous - edge * projection);
		if (candidate < distance) {
			distance = candidate;
			color_distance = walked + projection * edge_length;
		}
		walked += edge_length;
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
	vec3 tint = neon_color.rgb;
	if (gradient_enabled) {
		tint = texture(color_lookup, vec2(clamp(color_distance / max(color_length, 0.001), 0.0, 1.0), 0.5)).rgb;
	}
	float reveal = 1.0;
	float celebration = 0.0;
	if (completion_time >= 0.0) {
		float wave = clamp((completion_time - 0.18) / 1.25, 0.0, 1.0);
		float front = mix(130.0, 710.0, wave);
		reveal = (1.0 - smoothstep(front - 32.0, front + 32.0, p.y + origin_y)) * smoothstep(0.18, 0.30, completion_time);
		float crest = exp(-pow((p.y + origin_y - front) / 36.0, 2.0));
		float pulse = smoothstep(1.35, 1.60, completion_time) * (1.0 - smoothstep(1.70, 2.25, completion_time));
		celebration = max(crest * (1.0 - smoothstep(1.40, 1.60, completion_time)), pulse);
		float settled = smoothstep(1.80, 2.40, completion_time);
		celebration = max(celebration, settled * 0.20);
		alpha = fill + (1.0 - fill) * min(1.0, glow + (celebration * 0.32 + settled * 0.06) * exp(-outside / 5.0));
	}
	vec3 light = mix(tint, vec3(1.0), core * (0.24 + celebration * 0.26));
	COLOR = vec4(light, alpha * neon_color.a * selection_opacity * reveal);
}
