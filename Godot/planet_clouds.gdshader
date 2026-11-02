shader_type spatial;
render_mode blend_mix, depth_draw_never, cull_disabled, unshaded;

uniform sampler2D planetary_map : filter_linear_mipmap, repeat_enable;
uniform vec3 cloud_color : source_color = vec3(0.71, 0.85, 0.96);

void fragment() {
	float cloud = texture(planetary_map, UV).b;
	float polar_fade = 1.0 - smoothstep(0.88, 0.99, abs(UV.y * 2.0 - 1.0));
	ALBEDO = cloud_color;
	ALPHA = smoothstep(0.42, 0.7, cloud) * polar_fade * 0.24;
}
