shader_type spatial;
render_mode blend_mix, depth_prepass_alpha, cull_disabled;

uniform sampler2D hull_mask : source_color, filter_linear_mipmap, repeat_disable;
uniform vec4 alloy_color : source_color = vec4(0.48, 0.68, 0.76, 0.98);
uniform vec4 signal_color : source_color = vec4(0.18, 0.82, 0.96, 1.0);
uniform float damage = 0.5;
uniform float edge_softness = 0.08;
uniform bool mirror_u = false;

void fragment() {
	vec2 frame_uv = UV;
	if (mirror_u) {
		frame_uv.x = 1.0 - frame_uv.x;
	}
	float mask = texture(hull_mask, frame_uv).a;
	if (mask < 0.025) {
		discard;
	}

	float contour = 0.0;
	vec2 texel = 1.0 / vec2(textureSize(hull_mask, 0));
	for (int i = 0; i < 8; i++) {
		float angle = float(i) * 0.785398;
		vec2 offset = vec2(cos(angle), sin(angle)) * texel * 2.0;
		contour = max(contour, abs(mask - texture(hull_mask, frame_uv + offset).a));
	}

	float panel_u = abs(fract(frame_uv.x * 9.0) - 0.5);
	float panel_v = abs(fract(frame_uv.y * 5.0) - 0.5);
	float seam = 1.0 - smoothstep(0.012, 0.034, min(panel_u, panel_v));
	float rail = 1.0 - smoothstep(0.025, 0.065, min(frame_uv.y, 1.0 - frame_uv.y));
	float rivet_grid = step(0.91, fract(frame_uv.x * 18.0)) * step(0.91, fract(frame_uv.y * 8.0));
	float edge_light = smoothstep(0.02, 0.34, contour);
	float plate = 0.72 + 0.16 * sin(frame_uv.x * 71.0) + 0.11 * sin(frame_uv.y * 43.0);

	vec3 alloy = alloy_color.rgb * plate;
	alloy = mix(alloy, signal_color.rgb, seam * 0.22 + rail * 0.18);
	alloy += vec3(rivet_grid * 0.30);
	ALBEDO = alloy;
	METALLIC = 0.93;
	ROUGHNESS = clamp(0.22 + seam * 0.17, 0.16, 0.48);
	SPECULAR = 0.82;
	EMISSION = signal_color.rgb * (edge_light * (0.12 + damage * 0.48) + rail * 0.06);
	ALPHA = mask * alloy_color.a * (1.0 - edge_softness * seam);
}
