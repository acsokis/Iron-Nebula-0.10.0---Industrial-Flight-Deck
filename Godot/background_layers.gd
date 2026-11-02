extends Node3D

const PANORAMA_SHADER = preload("res://Godot/panorama_blend.gdshader")
const PLANET_SHADER = preload("res://Godot/planet_surface.gdshader")
const CLOUD_SHADER = preload("res://Godot/planet_clouds.gdshader")
const ATMOSPHERE_SHADER = preload("res://Godot/planet_atmosphere.gdshader")
const FIELD := Vector2(48.0, 27.0)
const BACKDROPS := ["spaceFrontier", "spaceRift", "spaceInferno"]
const PANORAMAS := ["frontier", "rift", "inferno"]
const CLOUDS := ["dofFar", "dofMid", "dofNear"]
const LAYER_SPEEDS := [0.09, 0.34, 1.2, 4.4]
const LAYER_DEPTHS := [-29.0, -19.0, -12.0, -6.5]
const LAYER_SCALES := [1.0, 1.8, 2.8, 3.8]

var base_tiles: Array[MeshInstance3D] = []
var panorama_tiles: Array[MeshInstance3D] = []
var drift_art: Array[MeshInstance3D] = []
var drift_origins: Array[Vector3] = []
var starfield: MultiMeshInstance3D
var star_origins: Array[Vector3] = []
var star_speeds: Array[float] = []
var planet_surfaces: Array[ShaderMaterial] = []
var planet_noise_textures: Array[ImageTexture] = []
var planet_clouds: Array[MeshInstance3D] = []
var planet_cloud_materials: Array[ShaderMaterial] = []
var planet_atmospheres: Array[ShaderMaterial] = []
var elapsed := 0.0
var sector := 0

func _ready() -> void:
	_build_base()
	_build_panorama()
	_build_planets()
	_build_starfield()
	_build_drift_art()
	set_sector(0)

func art(name: String) -> Texture2D:
	return load("res://Web/public/assets/%s.webp" % name) as Texture2D

func _build_base() -> void:
	var size := FIELD * (98.0 / 60.0)
	for index in range(3):
		var tile := MeshInstance3D.new()
		var quad := QuadMesh.new()
		quad.size = size
		tile.mesh = quad
		tile.position = Vector3((index - 1) * size.x, 0.0, -38.0)
		add_child(tile)
		base_tiles.append(tile)

func _build_panorama() -> void:
	var size := FIELD * (94.0 / 60.0)
	for index in range(3):
		var tile := MeshInstance3D.new()
		tile.name = "CelestialPanorama_%d" % index
		var quad := QuadMesh.new()
		quad.size = size
		tile.mesh = quad
		tile.position = Vector3((index - 1) * size.x, 0.0, -34.0)
		var material := ShaderMaterial.new()
		material.shader = PANORAMA_SHADER
		material.set_shader_parameter("tint", Color(0.9, 0.94, 1.0, 0.94))
		tile.material_override = material
		add_child(tile)
		panorama_tiles.append(tile)

func _build_starfield() -> void:
	var star_mesh := SphereMesh.new()
	star_mesh.radius = 0.035
	star_mesh.height = 0.07
	star_mesh.radial_segments = 5
	star_mesh.rings = 3
	var star_material := StandardMaterial3D.new()
	star_material.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	star_material.albedo_color = Color.WHITE
	star_material.emission_enabled = true
	star_material.emission = Color("98cfff")
	star_material.emission_energy_multiplier = 1.8
	star_mesh.material = star_material
	var batch := MultiMesh.new()
	batch.transform_format = MultiMesh.TRANSFORM_3D
	batch.use_colors = true
	batch.mesh = star_mesh
	batch.instance_count = 96
	starfield = MultiMeshInstance3D.new()
	starfield.multimesh = batch
	starfield.position.z = -24.0
	add_child(starfield)
	var rng := RandomNumberGenerator.new()
	rng.seed = 486213
	for index in range(batch.instance_count):
		var point := Vector3(rng.randf_range(-48.0, 48.0), rng.randf_range(-18.0, 18.0), 0.0)
		var size := rng.randf_range(0.38, 1.7)
		star_origins.append(point)
		star_speeds.append(rng.randf_range(0.025, 0.22))
		batch.set_instance_transform(index, Transform3D(Basis.from_scale(Vector3.ONE * size), point))
		batch.set_instance_color(index, Color(0.55 + rng.randf() * 0.45, 0.72 + rng.randf() * 0.28, 1.0, 0.45 + rng.randf() * 0.55))

func _build_planets() -> void:
	var planet_data := [
		{"name": "Aurelia", "position": Vector3(15.5, 6.8, -23.0), "radius": 6.4, "seed": 76231},
		{"name": "Nysa", "position": Vector3(-19.0, -8.0, -29.0), "radius": 2.65, "seed": 19487},
	]
	for data in planet_data:
		var planet := Node3D.new()
		planet.name = String(data["name"])
		planet.position = data["position"]
		add_child(planet)
		var planetary_map := _make_planet_noise_texture(int(data["seed"]))
		planet_noise_textures.append(planetary_map)

		var surface := MeshInstance3D.new()
		surface.name = "Surface"
		var sphere := SphereMesh.new()
		sphere.radius = float(data["radius"])
		sphere.height = sphere.radius * 2.0
		sphere.radial_segments = 48
		sphere.rings = 28
		surface.mesh = sphere
		var surface_material := ShaderMaterial.new()
		surface_material.shader = PLANET_SHADER
		surface_material.set_shader_parameter("planetary_map", planetary_map)
		surface.material_override = surface_material
		surface.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
		planet.add_child(surface)
		planet_surfaces.append(surface_material)

		var clouds := MeshInstance3D.new()
		clouds.name = "MovingClouds"
		var cloud_sphere := SphereMesh.new()
		cloud_sphere.radius = float(data["radius"]) * 1.014
		cloud_sphere.height = cloud_sphere.radius * 2.0
		cloud_sphere.radial_segments = 48
		cloud_sphere.rings = 28
		clouds.mesh = cloud_sphere
		var cloud_material := ShaderMaterial.new()
		cloud_material.shader = CLOUD_SHADER
		cloud_material.set_shader_parameter("planetary_map", planetary_map)
		clouds.material_override = cloud_material
		clouds.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
		planet.add_child(clouds)
		planet_clouds.append(clouds)
		planet_cloud_materials.append(cloud_material)

		var atmosphere := MeshInstance3D.new()
		atmosphere.name = "Atmosphere"
		var shell := SphereMesh.new()
		shell.radius = float(data["radius"]) * 1.075
		shell.height = shell.radius * 2.0
		shell.radial_segments = 48
		shell.rings = 28
		atmosphere.mesh = shell
		var atmosphere_material := ShaderMaterial.new()
		atmosphere_material.shader = ATMOSPHERE_SHADER
		atmosphere.material_override = atmosphere_material
		atmosphere.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
		planet.add_child(atmosphere)
		planet_atmospheres.append(atmosphere_material)

	set_sector(sector)

func _make_planet_noise_texture(seed_value: int) -> ImageTexture:
	const TEXTURE_WIDTH := 384
	const TEXTURE_HEIGHT := 192
	var terrain_noise := _planet_noise(seed_value, 2.5, 4)
	var detail_noise := _planet_noise(seed_value + 73, 7.0, 3)
	var cloud_noise := _planet_noise(seed_value + 149, 3.8, 4)
	var image := Image.create(TEXTURE_WIDTH, TEXTURE_HEIGHT, false, Image.FORMAT_RGBA8)
	for y in range(TEXTURE_HEIGHT):
		var latitude := (float(y) + 0.5) / TEXTURE_HEIGHT * PI - PI * 0.5
		for x in range(TEXTURE_WIDTH):
			var longitude := (float(x) + 0.5) / TEXTURE_WIDTH * TAU
			var direction := Vector3(cos(latitude) * cos(longitude), sin(latitude), cos(latitude) * sin(longitude))
			var terrain := terrain_noise.get_noise_3d(direction.x, direction.y, direction.z) * 0.5 + 0.5
			var detail := detail_noise.get_noise_3d(direction.x, direction.y, direction.z) * 0.5 + 0.5
			var cloud := cloud_noise.get_noise_3d(direction.x, direction.y, direction.z) * 0.5 + 0.5
			image.set_pixel(x, y, Color(terrain, detail, cloud))
	var texture := ImageTexture.create_from_image(image)
	return texture

func _planet_noise(seed_value: int, frequency: float, octaves: int) -> FastNoiseLite:
	var noise := FastNoiseLite.new()
	noise.seed = seed_value
	noise.noise_type = FastNoiseLite.TYPE_SIMPLEX_SMOOTH
	noise.fractal_type = FastNoiseLite.FRACTAL_FBM
	noise.fractal_octaves = octaves
	noise.frequency = frequency
	noise.fractal_lacunarity = 2.0
	noise.fractal_gain = 0.48
	return noise

func _build_drift_art() -> void:
	var rng := RandomNumberGenerator.new()
	rng.seed = 902741
	for layer in range(CLOUDS.size()):
		for index in range(5):
			var visual := MeshInstance3D.new()
			visual.name = "ParallaxDetail_%d_%d" % [layer, index]
			var quad := QuadMesh.new()
			var scale: float = LAYER_SCALES[layer]
			quad.size = Vector2.ONE * scale * rng.randf_range(0.7, 1.35)
			visual.mesh = quad
			var material := StandardMaterial3D.new()
			material.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
			material.albedo_texture = art(CLOUDS[layer])
			material.albedo_color = Color(0.72, 0.84, 0.96, 0.72 if layer < 2 else 0.86)
			material.emission_enabled = true
			material.emission = Color("61788f")
			material.emission_energy_multiplier = 0.28
			material.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
			material.cull_mode = BaseMaterial3D.CULL_DISABLED
			visual.material_override = material
			var origin := Vector3(rng.randf_range(-42.0, 42.0), rng.randf_range(-17.0, 17.0), LAYER_DEPTHS[layer])
			visual.position = origin
			visual.rotation.z = rng.randf_range(-PI, PI)
			add_child(visual)
			drift_art.append(visual)
			drift_origins.append(origin)

func set_sector(value: int) -> void:
	sector = posmod(value, BACKDROPS.size())
	var background := art(BACKDROPS[sector])
	for tile in base_tiles:
		var material := StandardMaterial3D.new()
		material.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
		material.albedo_texture = background
		material.albedo_color = Color.BLACK
		material.emission_enabled = true
		material.emission = Color.WHITE
		material.cull_mode = BaseMaterial3D.CULL_DISABLED
		tile.material_override = material
	var panorama := art(PANORAMAS[sector])
	for tile in panorama_tiles:
		var material := tile.material_override as ShaderMaterial
		material.set_shader_parameter("panorama", panorama)
	var surface_colors := [
		[Color("102d42"), Color("568578"), Color("c5d5d8"), Color("53cafa")],
		[Color("211d42"), Color("78728c"), Color("d2c9e8"), Color("bb8cff")],
		[Color("401b24"), Color("a96743"), Color("edc6a1"), Color("ff765c")],
	]
	var colors: Array = surface_colors[sector]
	for surface in planet_surfaces:
		surface.set_shader_parameter("ocean_color", colors[0])
		surface.set_shader_parameter("land_color", colors[1])
		surface.set_shader_parameter("ice_color", colors[2])
	for cloud_material in planet_cloud_materials:
		cloud_material.set_shader_parameter("cloud_color", colors[2])
	for atmosphere in planet_atmospheres:
		atmosphere.set_shader_parameter("atmosphere_color", colors[3])

func layer_count() -> int:
	return 4

func _process(delta: float) -> void:
	elapsed += delta
	var panorama_width := FIELD.x * (94.0 / 60.0)
	var panorama_shift := fposmod(elapsed * LAYER_SPEEDS[0], panorama_width)
	for index in range(panorama_tiles.size()):
		panorama_tiles[index].position.x = (index - 1) * panorama_width - panorama_shift
	var base_width := FIELD.x * (98.0 / 60.0)
	var base_shift := fposmod(elapsed * 0.035, base_width)
	for index in range(base_tiles.size()):
		base_tiles[index].position.x = (index - 1) * base_width - base_shift
	var batch := starfield.multimesh
	for index in range(star_origins.size()):
		var point := star_origins[index]
		point.x = fposmod(point.x - elapsed * star_speeds[index] + 48.0, 96.0) - 48.0
		batch.set_instance_transform(index, Transform3D(batch.get_instance_transform(index).basis, point))
	for index in range(drift_art.size()):
		var origin := drift_origins[index]
		var layer := floori(float(index) / 5.0)
		origin.x = fposmod(drift_origins[index].x - elapsed * LAYER_SPEEDS[layer] + 42.0, 84.0) - 42.0
		drift_art[index].position = origin
	for index in range(planet_clouds.size()):
		planet_clouds[index].rotation.y += delta * (0.008 if index == 0 else -0.013)
		planet_cloud_materials[index].set_shader_parameter("cloud_time", elapsed)
	for index in range(planet_surfaces.size()):
		planet_surfaces[index].set_shader_parameter("cloud_time", elapsed)
