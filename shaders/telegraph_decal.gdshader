shader_type spatial;
render_mode unshaded, blend_mix, depth_draw_never, cull_disabled, shadows_disabled;

uniform vec4 decal_color : source_color = vec4(1.0, 0.28, 0.12, 0.95);
uniform float progress : hint_range(0.0, 1.0) = 0.0; // 0 = vacío, 1 = relleno
uniform float visibility_scale : hint_range(0.25, 2.0) = 1.0;
uniform float outline_scale : hint_range(0.0, 2.0) = 1.0;
uniform float pulse_speed : hint_range(0.0, 20.0) = 8.0;
uniform float flash : hint_range(0.0, 1.0) = 0.0;    // destello en el impacto

void fragment() {
	vec2 p = UV * 2.0 - 1.0;
	float d = length(p);
	// El borde se dibuja desde el comienzo y define exactamente la zona peligrosa.
	float outside = 1.0 - smoothstep(0.975, 1.0, d);
	float ring_inner = smoothstep(0.80, 0.88, d);
	float ring_outer = 1.0 - smoothstep(0.94, 0.99, d);
	float ring = ring_inner * ring_outer * outline_scale;
	// El disco interior se llena gradualmente conforme se acerca el impacto.
	float fill = 1.0 - smoothstep(progress - 0.05, progress + 0.05, d);
	fill *= outside * 0.42;
	float pulse = pulse_speed <= 0.01 ? 1.0 : (0.86 + 0.14 * sin(TIME * pulse_speed));
	float alpha = clamp(max(ring, fill) * pulse + flash, 0.0, 1.0);
	ALBEDO = decal_color.rgb;
	EMISSION = decal_color.rgb * (1.3 + flash * 2.0);
	ALPHA = clamp(alpha * decal_color.a * visibility_scale, 0.0, 1.0);
}
