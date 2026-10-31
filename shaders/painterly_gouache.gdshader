shader_type canvas_item;
render_mode unshaded;
// Post-proceso "gouache pictórico" para horror cósmico:
// posteriza el color, dibuja un contorno de tinta, añade grano de papel,
// tiñe las sombras de violeta y aplica una viñeta.

uniform sampler2D screen_tex : hint_screen_texture, filter_linear;
uniform float posterize_levels : hint_range(4.0, 32.0) = 9.0;
uniform float outline_strength : hint_range(0.0, 1.0) = 0.45;
uniform float grain_strength : hint_range(0.0, 0.25) = 0.06;
uniform float vignette_strength : hint_range(0.0, 1.0) = 0.45;
uniform vec3 paper_tint : source_color = vec3(0.96, 0.93, 0.86);
uniform vec3 shadow_tint : source_color = vec3(0.42, 0.28, 0.55);

float lum(vec3 c) {
	return dot(c, vec3(0.299, 0.587, 0.114));
}

float hash21(vec2 p) {
	p = fract(p * vec2(123.34, 456.21));
	p += dot(p, p + 45.32);
	return fract(p.x * p.y);
}

void fragment() {
	vec2 uv = SCREEN_UV;
	vec3 col = texture(screen_tex, uv).rgb;

	// 1. Posterizado pictórico: reduce las bandas de color a planos de gouache.
	float l = lum(col);
	float q = floor(l * posterize_levels + 0.5) / posterize_levels;
	col = mix(col, col * (q / max(l, 0.001)), 0.7);

	// 2. Trazo de tinta: oscurece las transiciones de luminancia.
	vec2 px = SCREEN_PIXEL_SIZE * 1.5;
	float lx = lum(texture(screen_tex, uv + vec2(px.x, 0.0)).rgb)
	         - lum(texture(screen_tex, uv - vec2(px.x, 0.0)).rgb);
	float ly = lum(texture(screen_tex, uv + vec2(0.0, px.y)).rgb)
	         - lum(texture(screen_tex, uv - vec2(0.0, px.y)).rgb);
	float edge = clamp(sqrt(lx * lx + ly * ly) * 5.0, 0.0, 1.0);
	col = mix(col, col * 0.5, edge * outline_strength);

	// 3. Papel cálido + sombras violáceas cósmicas.
	col *= paper_tint;
	float darkness = clamp(1.0 - l * 2.2, 0.0, 1.0);
	col = mix(col, col * shadow_tint * 1.8, darkness * 0.3);

	// 4. Grano de papel estático.
	float g = hash21(floor(uv * vec2(512.0, 288.0))) - 0.5;
	col += g * grain_strength;

	// 5. Viñeta.
	float d = distance(uv, vec2(0.5));
	col *= mix(1.0, 1.0 - vignette_strength, smoothstep(0.35, 0.9, d));

	COLOR = vec4(col, 1.0);
}