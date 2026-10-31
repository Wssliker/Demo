shader_type canvas_item;
render_mode unshaded;

uniform float intensity : hint_range(0.0, 1.0) = 0.0;
uniform vec4 danger_color : source_color = vec4(0.62, 0.0, 0.06, 1.0);

void fragment() {
	float d = distance(UV, vec2(0.5));
	float v = smoothstep(0.22, 0.72, d);
	float pulse = 0.85 + 0.15 * sin(TIME * 6.0);
	COLOR = vec4(danger_color.rgb, v * intensity * pulse);
}