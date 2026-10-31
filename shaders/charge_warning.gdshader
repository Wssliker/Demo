shader_type spatial;
render_mode unshaded, blend_mix, cull_disabled, depth_draw_never;

uniform vec4 ink_color : source_color = vec4(0.43, 0.08, 0.16, 0.70);
uniform vec4 edge_color : source_color = vec4(0.85, 0.37, 0.23, 0.95);
uniform float pulse_speed : hint_range(0.1, 8.0) = 2.8;

void fragment() {
	vec2 p = UV * 2.0 - 1.0;
	float side = abs(p.x);
	float irregular = 0.06 * sin(p.y * 23.0 + TIME * 0.8) * sin(p.y * 11.0);
	float inside = 1.0 - smoothstep(0.77 + irregular, 0.97 + irregular, side);
	float center = 1.0 - smoothstep(0.05, 0.72, side);
	float edge = smoothstep(0.55, 0.80, side) * inside;
	float end_fade = 1.0 - smoothstep(0.78, 1.0, abs(p.y));
	float pulse = 0.83 + 0.17 * sin(TIME * pulse_speed);
	ALBEDO = mix(ink_color.rgb, edge_color.rgb, edge) * pulse;
	EMISSION = edge_color.rgb * edge * 0.55;
	ALPHA = (ink_color.a * center * 0.42 + edge_color.a * edge * 0.65) * inside * end_fade * pulse;
}
