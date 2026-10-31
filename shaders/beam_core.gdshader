shader_type spatial;
render_mode unshaded, blend_add, cull_disabled, depth_draw_never;

uniform vec4 core_color : source_color = vec4(0.78, 0.38, 0.54, 1.0);
uniform float firing = 0.0;

void fragment() {
    float streak = 0.88 + 0.12 * sin(UV.y * 36.0 - TIME * 9.0);
    float band = 0.7 + 0.3 * sin(UV.y * 16.0 + TIME * 5.0);
    vec3 idle = vec3(0.28, 0.08, 0.18);
    vec3 active = mix(core_color.rgb, vec3(0.92, 0.78, 0.88), 0.18);
    vec3 pigment = mix(idle, active, firing);
    ALBEDO = pigment;
    EMISSION = pigment * mix(0.65, 1.45, firing) * streak * band;
    ALPHA = mix(0.10, 0.42, firing) * streak;
}
