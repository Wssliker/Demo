shader_type spatial;
render_mode unshaded, blend_mix, depth_draw_alpha_prepass, cull_disabled;

uniform vec4 base_color : source_color = vec4(0.45, 0.06, 0.11, 0.62);
uniform vec4 edge_color : source_color = vec4(0.92, 0.24, 0.14, 0.88);
uniform float locked = 0.0;
uniform float line_length = 8.0;

void fragment() {
	vec2 uv = UV;
	float center = abs(uv.x - 0.5) * 2.0;
	float body = smoothstep(1.0, 0.35, center);
	float edge = smoothstep(0.55, 0.18, center);
	float pulse = 0.55 + 0.45 * sin(TIME * 6.0 + uv.y * 10.0);
	float drift = sin((uv.y * line_length * 0.7) - TIME * 3.5) * 0.08;
	float breakup = smoothstep(0.18, 0.95, body + drift);
	vec3 col = mix(base_color.rgb, edge_color.rgb, edge);
	float alpha = base_color.a * breakup * mix(0.9, 1.25, locked) * pulse;
	if (locked > 0.5) {
		col = mix(col, vec3(1.0, 0.52, 0.12), 0.35 + 0.25 * pulse);
		alpha *= 1.15;
	}
	ALBEDO = col;
	EMISSION = col * (0.9 + locked * 0.7);
	ALPHA = clamp(alpha, 0.0, 1.0);
}
