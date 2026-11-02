shader_type spatial;
render_mode diffuse_burley, specular_schlick_ggx;

uniform sampler2D planetary_map : filter_linear_mipmap, repeat_enable;
uniform vec3 ocean_color : source_color = vec3(0.035, 0.16, 0.28);
uniform vec3 land_color : source_color = vec3(0.22, 0.35, 0.28);
uniform vec3 ice_color : source_color = vec3(0.68, 0.77, 0.76);

void fragment() {
	vec3 terrain_map = texture(planetary_map, UV).rgb;
	float continent = smoothstep(0.43, 0.58, terrain_map.r + (terrain_map.g - 0.5) * 0.18);
	float terrain_detail = smoothstep(0.27, 0.76, terrain_map.g);
	float polar = smoothstep(0.8, 0.98, abs(NORMAL.y));
	vec3 land = mix(land_color * 0.68, land_color * 1.42, terrain_detail);
	ALBEDO = mix(ocean_color * (0.82 + terrain_detail * 0.32), land, continent);
	ALBEDO = mix(ALBEDO, ice_color, polar * (0.42 + 0.28 * terrain_detail));
	ROUGHNESS = mix(0.34, 0.84, continent);
	METALLIC = 0.025;
	SPECULAR = 0.72;
	EMISSION = ocean_color * (0.018 + terrain_detail * 0.02);
}
