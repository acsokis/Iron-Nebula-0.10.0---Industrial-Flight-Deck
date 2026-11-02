shader_type spatial;
render_mode blend_mix, depth_prepass_alpha, cull_disabled, unshaded;

uniform sampler2D panorama : source_color, filter_linear_mipmap, repeat_disable;
uniform vec4 tint : source_color = vec4(1.0);
uniform float edge_fade = 0.075;

void fragment() {
	vec4 color = texture(panorama, UV) * tint;
	float horizontal = smoothstep(0.0, edge_fade, UV.x) * smoothstep(0.0, edge_fade, 1.0 - UV.x);
	float vertical = smoothstep(0.0, 0.045, UV.y) * smoothstep(0.0, 0.045, 1.0 - UV.y);
	ALBEDO = color.rgb;
	ALPHA = color.a * horizontal * vertical;
}
