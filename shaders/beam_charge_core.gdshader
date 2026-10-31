shader_type spatial;
render_mode unshaded, blend_add, cull_disabled, depth_draw_never;

uniform vec4 base_color : source_color = vec4(0.34, 0.05, 0.12, 1.0);
uniform vec4 hot_color : source_color = vec4(0.75, 0.24, 0.34, 1.0);
uniform float energy = 1.0;
uniform float locked = 0.0;

void fragment() {
	vec2 p = UV * 2.0 - 1.0;
	float r = length(p);
	float core = smoothstep(0.92, 0.0, r);
	float ring = smoothstep(0.62, 0.42, abs(r - (0.45 + sin(TIME * 4.0) * 0.03)));
	float flare = 0.65 + 0.35 * sin(TIME * 8.0);
	vec3 col = mix(base_color.rgb, hot_color.rgb, clamp(energy * 0.45 + locked * 0.25, 0.0, 1.0));
	float alpha = core * (0.35 + energy * 0.28) + ring * 0.20 * flare;
	ALBEDO = col;
	EMISSION = col * (0.9 + energy * 1.3 + locked * 0.8);
	ALPHA = clamp(alpha, 0.0, 1.0);
}
