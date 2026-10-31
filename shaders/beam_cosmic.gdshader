shader_type spatial;
render_mode unshaded, blend_add, cull_disabled, depth_draw_never;

uniform vec4 cold_tint : source_color = vec4(0.16, 0.03, 0.14, 1.0);
uniform vec4 hot_tint : source_color = vec4(0.62, 0.10, 0.20, 1.0);
uniform float firing = 0.0;
uniform float opacity : hint_range(0.0, 1.0) = 0.46;
uniform float turbulence : hint_range(0.0, 4.0) = 1.10;

void fragment() {
    float theta = UV.x * 6.2831853;
    float v = UV.y;
    float ripple = sin(theta * 4.0 + v * 18.0 - TIME * 6.5) * 0.22;
    ripple += sin(theta * 7.0 - v * 24.0 + TIME * 7.5) * 0.10;
    float veil = 0.55 + (ripple * turbulence);
    float pulse = 0.90 + 0.10 * sin(TIME * 9.0 + v * 8.0);
    vec3 pigment = mix(cold_tint.rgb, hot_tint.rgb, clamp(0.2 + firing * 0.55 + veil * 0.18, 0.0, 1.0));
    ALBEDO = pigment;
    EMISSION = pigment * (0.75 + firing * 1.25) * pulse;
    ALPHA = clamp(opacity * (0.45 + veil * 0.35), 0.0, 1.0);
}
