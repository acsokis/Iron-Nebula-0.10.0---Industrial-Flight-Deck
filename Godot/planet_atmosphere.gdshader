shader_type spatial;
render_mode blend_add, depth_draw_never, cull_front, unshaded;

uniform vec3 atmosphere_color : source_color = vec3(0.13, 0.62, 1.0);
uniform float atmosphere_strength = 0.52;

void fragment() {
	float fresnel = pow(1.0 - max(dot(normalize(NORMAL), normalize(VIEW)), 0.0), 3.1);
	ALBEDO = atmosphere_color;
	EMISSION = atmosphere_color * (0.12 + fresnel * 1.2);
	ALPHA = fresnel * atmosphere_strength;
}
