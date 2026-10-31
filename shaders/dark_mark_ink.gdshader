shader_type spatial;
render_mode unshaded, cull_disabled, blend_mix, depth_draw_never;

uniform vec4 ink_color : source_color = vec4(0.13, 0.045, 0.20, 1.0);
uniform vec4 rim_color : source_color = vec4(0.66, 0.18, 0.39, 1.0);
uniform float fade : hint_range(0.0, 1.0) = 1.0;
uniform float flow_speed : hint_range(0.0, 2.0) = 0.4;

float hash(vec2 p) {
    return fract(sin(dot(p, vec2(127.1, 311.7))) * 43758.5453);
}

float noise(vec2 p) {
    vec2 i = floor(p);
    vec2 f = fract(p);
    vec2 u = f * f * (3.0 - 2.0 * f);
    return mix(mix(hash(i), hash(i + vec2(1.0, 0.0)), u.x),
               mix(hash(i + vec2(0.0, 1.0)), hash(i + vec2(1.0, 1.0)), u.x), u.y);
}

void fragment() {
    vec2 p = UV * 2.0 - 1.0;
    float n = noise(p * 6.5 + vec2(TIME * flow_speed * 0.1, -TIME * flow_speed * 0.12));
    float distort = (n - 0.5) * 0.13;
    float radial = length(p) + distort;
    float mask = 1.0 - smoothstep(0.78, 1.0, radial);
    float rim = smoothstep(0.55, 0.80, radial) * (1.0 - smoothstep(0.83, 1.0, radial));
    float veins = noise(p * 13.0 - vec2(0.0, TIME * 0.07));
    vec3 color = mix(ink_color.rgb, rim_color.rgb, rim * 0.65 + veins * 0.12);
    ALBEDO = color;
    EMISSION = rim_color.rgb * rim * 0.18;
    ALPHA = mask * (0.74 + 0.12 * n) * fade;
}
