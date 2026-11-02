extends Node3D

const SEED_VALUE = 87321
const VOXEL_DEBRIS_LIMIT = 16
const EFFECT_LIMIT = 36
const SPARK_LIMIT = 12
const WORLD_LAYER = 4
var rng := RandomNumberGenerator.new()
var orbiters: Array[RigidBody3D] = []
var effects: Array[AnimatedSprite3D] = []
var spark_bursts: Array[GPUParticles3D] = []
var shock_rings: Array[Dictionary] = []
var clock := 0.0
var spawn_timer := 0.0
var smoke_frames: SpriteFrames
var explosion_frames: SpriteFrames
var sector := 0

func _ready() -> void:
	rng.seed = int(ProjectSettings.get_setting("iron_nebula/world/seed", SEED_VALUE))
	_build_effect_frames()
	make_station(Vector3(11, -8, 0))
	var reservations: Array[Vector3] = [Vector3(11, -8, 0), Vector3(-13, 0, 0)]
	for index in range(12):
		var candidate := Vector3(rng.randf_range(-6, 31), rng.randf_range(-11, 11), 0)
		var free := true
		for previous in reservations:
			if previous.distance_to(candidate) < 5.2:
				free = false
				break
		if free:
			reservations.append(candidate)
			make_orbiter(candidate, index % 4 == 0)

func set_sector(value: int) -> void:
	sector = posmod(value, 3)
	var accent_color := Color("f49b55") if sector == 2 else Color("ae8bff") if sector == 1 else Color("57e3f5")
	for body in orbiters:
		if not is_instance_valid(body) or body.is_queued_for_deletion():
			continue
		for cell in body.get_meta("voxel_cells", []):
			if not cell is Dictionary or not cell.get("signal_accent", false):
				continue
			cell["color"] = accent_color
		_rebuild_voxel_batches(body)

func _build_effect_frames() -> void:
	smoke_frames = _make_frames("damageSmoke", 3, 4, 17.0)
	explosion_frames = _make_frames("explosion", 4, 2, 19.0)

func _make_frames(texture_name: String, columns: int, rows: int, frame_rate: float) -> SpriteFrames:
	var texture := load("res://Web/public/assets/%s.webp" % texture_name) as Texture2D
	var frame_size := texture.get_size() / Vector2(columns, rows)
	var frames := SpriteFrames.new()
	frames.add_animation("burst")
	frames.set_animation_speed("burst", frame_rate)
	frames.set_animation_loop("burst", false)
	for frame_index in range(columns * rows):
		var frame := AtlasTexture.new()
		frame.atlas = texture
		frame.region = Rect2(
			Vector2(frame_index % columns, frame_index / columns) * frame_size,
			frame_size
		)
		frames.add_frame("burst", frame)
	return frames

func _play_effect(atlas: SpriteFrames, world_position: Vector3, size: float) -> void:
	effects = effects.filter(func(effect: AnimatedSprite3D) -> bool: return is_instance_valid(effect) and not effect.is_queued_for_deletion())
	if effects.size() >= EFFECT_LIMIT:
		return
	var effect := AnimatedSprite3D.new()
	effect.sprite_frames = atlas
	effect.animation = "burst"
	effect.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	effect.pixel_size = 0.01
	effect.scale = Vector3.ONE * size
	effect.position = world_position
	effect.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	add_child(effect)
	effect.animation_finished.connect(_finish_effect.bind(effect))
	effects.append(effect)
	effect.play()

func _finish_effect(effect: AnimatedSprite3D) -> void:
	effects.erase(effect)
	effect.queue_free()

func spawn_hit_fx(world_position: Vector3) -> void:
	_play_effect(smoke_frames, world_position, 0.42)

func spawn_destruction_fx(world_position: Vector3, size: float) -> void:
	_play_effect(explosion_frames, world_position, clampf(size, 0.38, 1.35))
	_play_effect(smoke_frames, world_position + Vector3(0, 0.18, 0), clampf(size * 0.9, 0.45, 1.5))
	_spawn_sparks(world_position, 32, 9.0)
	_spawn_shock_ring(world_position, size)

func material(color: Color, emissive: bool = false, metalness: float = 0.18) -> StandardMaterial3D:
	var result := StandardMaterial3D.new()
	result.albedo_color = color
	result.roughness = 0.48 if metalness >= 0.65 else 0.84 if not emissive else 0.38
	result.metallic = metalness if not emissive else maxf(metalness, 0.82)
	result.emission_enabled = true
	result.emission = color * (0.65 if metalness >= 0.65 else 0.34)
	result.emission_energy_multiplier = 1.0 if not emissive else 1.8
	return result

func _new_body(body_name: String, center: Vector3, health: int, mass_value: float) -> RigidBody3D:
	var body := RigidBody3D.new()
	body.name = body_name
	body.gravity_scale = 0.0
	body.axis_lock_linear_z = true
	body.continuous_cd = true
	body.linear_damp = 0.22
	body.angular_damp = 0.35
	body.mass = mass_value
	body.collision_layer = WORLD_LAYER
	body.collision_mask = 1 | 2 | WORLD_LAYER
	body.position = center
	body.set_meta("health", health)
	body.set_meta("max_health", health)
	body.set_meta("voxel_cells", [])
	body.set_meta("voxel_batches", {})
	body.set_meta("age", 0.0)
	add_child(body)
	orbiters.append(body)
	return body

func _add_voxel(body: RigidBody3D, local_position: Vector3, size: Vector3, color: Color, accent: bool = false, rounded: bool = false, metalness: float = 0.18) -> void:
	var batch_key := "signal_sphere" if accent and rounded else "signal_block" if accent else "rock" if rounded else "metal"
	var cells: Array = body.get_meta("voxel_cells", [])
	cells.append({
		"position": local_position,
		"size": size,
		"color": color,
		"signal_accent": accent,
		"metalness": metalness,
		"batch": batch_key,
	})
	body.set_meta("voxel_cells", cells)

func _rebuild_voxel_batches(body: RigidBody3D) -> void:
	var batches: Dictionary = body.get_meta("voxel_batches", {})
	var grouped: Dictionary = {}
	for cell: Dictionary in body.get_meta("voxel_cells", []):
		var key: String = cell["batch"]
		if not grouped.has(key):
			grouped[key] = []
		grouped[key].append(cell)
	for key: String in grouped:
		var entries: Array = grouped[key]
		var batch_node := batches.get(key) as MultiMeshInstance3D
		if batch_node == null:
			batch_node = MultiMeshInstance3D.new()
			batch_node.name = "VoxelBatch_" + key
			var multi := MultiMesh.new()
			multi.transform_format = MultiMesh.TRANSFORM_3D
			multi.use_colors = true
			if key == "rock" or key == "signal_sphere":
				var sphere := SphereMesh.new()
				sphere.radius = 0.5
				sphere.height = 0.92
				sphere.radial_segments = 8
				sphere.rings = 4
				multi.mesh = sphere
			else:
				multi.mesh = BoxMesh.new()
			batch_node.multimesh = multi
			var voxel_material := StandardMaterial3D.new()
			voxel_material.vertex_color_use_as_albedo = true
			voxel_material.roughness = 0.82 if key == "rock" or key == "signal_sphere" else 0.32
			voxel_material.metallic = 0.08 if key == "rock" or key == "signal_sphere" else 0.78
			if key.begins_with("signal"):
				voxel_material.emission_enabled = true
				voxel_material.emission = Color.WHITE
				voxel_material.emission_energy_multiplier = 1.15
			batch_node.material_override = voxel_material
			batch_node.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
			batch_node.gi_mode = GeometryInstance3D.GI_MODE_DISABLED
			body.add_child(batch_node)
			batches[key] = batch_node
		var multi := batch_node.multimesh
		multi.instance_count = entries.size()
		for index in range(entries.size()):
			var cell: Dictionary = entries[index]
			var basis := Basis.from_scale(cell["size"])
			if key == "rock" or key == "signal_sphere":
				basis = basis.scaled_local(Vector3(0.56, 1.0, 0.56))
			multi.set_instance_transform(index, Transform3D(basis, cell["position"]))
			multi.set_instance_color(index, cell["color"])
	for key: String in batches:
		if not grouped.has(key):
			(batches[key] as MultiMeshInstance3D).multimesh.instance_count = 0
	body.set_meta("voxel_batches", batches)

func _add_collision(body: RigidBody3D, shape: Shape3D, local_position: Vector3 = Vector3.ZERO) -> void:
	var collision := CollisionShape3D.new()
	collision.shape = shape
	collision.position = local_position
	body.add_child(collision)

func make_station(center: Vector3) -> RigidBody3D:
	var station := _new_body("MiningStation", center, 28, 62.0)
	var cell := 0.56
	for y in range(-4, 5):
		for x in range(-6, 7):
			var core: bool = absf(float(x)) <= 2 and abs(y) <= 1
			var gantry: bool = absf(float(x)) <= 5 and abs(y) == 2 and x % 2 == 0
			var arm: bool = absf(float(y)) == 4 and absf(float(x)) <= 4 and x % 3 == 0
			var side_pylon: bool = absf(float(x)) == 6 and abs(y) <= 2 and y % 2 == 0
			if core or gantry or arm or side_pylon:
				var color := Color("82949c") if (x + y) % 3 == 0 else Color("65767e")
				_add_voxel(station, Vector3(x * cell, y * cell, 0), Vector3.ONE * cell * 0.94, color, false, false, 0.72)
			if core and x % 2 == 0 and y == 0:
				_add_voxel(station, Vector3(x * cell, y * cell, 0.31), Vector3(0.35, 0.10, 0.10), Color("57e3f5"), true, false, 0.88)
	var station_shape := BoxShape3D.new()
	station_shape.size = Vector3(7.5, 5.6, 1.4)
	_add_collision(station, station_shape)
	_rebuild_voxel_batches(station)
	station.set_meta("station", true)
	station.set_meta("sector_color", sector)
	station.linear_velocity = Vector3(-0.2, 0, 0)
	return station

func _make_asteroid_voxels(body: RigidBody3D, radius: float, wreck: bool) -> void:
	var cell_size := radius * (0.63 if not wreck else 0.58)
	for z in range(-1, 2):
		for y in range(-2, 3):
			for x in range(-2, 3):
				var point := Vector3(x * 0.52, y * 0.43, z * 0.66)
				if point.length() > 1.22 or rng.randf() < (0.16 if not wreck else 0.11):
					continue
				if wreck and absf(point.y) > 0.68 and absf(point.x) > 0.55:
					continue
				var variation := rng.randf_range(0.78, 1.18)
				var base := Color("58616a") if not wreck else Color("65747c")
				var color := base * variation
				var accent := rng.randf() < 0.075
				if accent:
					color = Color("36c9e6") if sector != 2 else Color("f49b55")
				_add_voxel(body, point * radius, Vector3.ONE * cell_size * rng.randf_range(0.82, 1.0), color, accent, true, 0.06)

func make_orbiter(center: Vector3, wreck: bool) -> RigidBody3D:
	var radius := rng.randf_range(0.65, 1.4)
	var health := ceili(radius * (8.0 if wreck else 7.0))
	var body := _new_body("Wreck" if wreck else "VoxelAsteroid", center, health, radius * radius * 9.0)
	_make_asteroid_voxels(body, radius, wreck)
	_rebuild_voxel_batches(body)
	var artwork := Sprite3D.new()
	artwork.name = "RockArt"
	artwork.texture = load("res://Web/public/assets/%s.webp" % ("rock" if wreck else "rock2")) as Texture2D
	artwork.pixel_size = 0.01
	artwork.scale = Vector3.ONE * radius * 0.39
	artwork.position.z = 1.25
	artwork.modulate = Color(1.0, 1.0, 1.0, 0.82)
	artwork.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	var artwork_material := StandardMaterial3D.new()
	artwork_material.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	artwork_material.albedo_texture = artwork.texture
	artwork_material.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	artwork_material.cull_mode = BaseMaterial3D.CULL_DISABLED
	artwork.material_override = artwork_material
	body.add_child(artwork)
	var collider_radius := radius * (0.87 if not wreck else 0.96)
	var shape := SphereShape3D.new()
	shape.radius = collider_radius
	_add_collision(body, shape)
	body.set_meta("wreck", wreck)
	body.set_meta("voxel_debris", false)
	body.linear_velocity = Vector3(-rng.randf_range(0.35, 0.95), rng.randf_range(-0.2, 0.2), 0)
	body.angular_velocity.z = rng.randf_range(-0.24, 0.24)
	return body

func _spawn_voxel_debris(world_position: Vector3, velocity: Vector3, color: Color, scale: float) -> void:
	if orbiters.size() >= 48:
		return
	var chunk := _new_body("VoxelDebris", world_position, 1, 0.45)
	var size := maxf(0.12, scale)
	var shard := MeshInstance3D.new()
	shard.name = "FractureShard"
	var mesh := PrismMesh.new()
	mesh.size = Vector3(size * 1.35, size, size * 0.82)
	mesh.material = material(color, false, 0.08)
	shard.mesh = mesh
	shard.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	chunk.add_child(shard)
	var shape := ConvexPolygonShape3D.new()
	shape.points = PackedVector3Array([
		Vector3(-0.5, -0.5, -0.5), Vector3(0.5, -0.5, -0.5), Vector3(0.0, 0.5, -0.5),
		Vector3(-0.5, -0.5, 0.5), Vector3(0.5, -0.5, 0.5), Vector3(0.0, 0.5, 0.5),
	])
	var collision := CollisionShape3D.new()
	collision.shape = shape
	collision.scale = Vector3.ONE * size
	chunk.add_child(collision)
	chunk.collision_mask = 1 | 2
	chunk.set_meta("voxel_debris", true)
	chunk.set_meta("lifetime", 8.0)
	chunk.linear_velocity = velocity
	chunk.angular_velocity = Vector3(rng.randf_range(-2.2, 2.2), rng.randf_range(-2.2, 2.2), rng.randf_range(-2.2, 2.2))

func _spawn_sparks(world_position: Vector3, count: int, speed: float) -> void:
	spark_bursts = spark_bursts.filter(func(burst: GPUParticles3D) -> bool: return is_instance_valid(burst) and not burst.is_queued_for_deletion())
	if spark_bursts.size() >= SPARK_LIMIT:
		return
	var burst := GPUParticles3D.new()
	burst.name = "3DSparkBurst"
	burst.amount = count
	burst.lifetime = 0.65
	burst.one_shot = true
	burst.explosiveness = 0.94
	burst.position = world_position
	var process := ParticleProcessMaterial.new()
	process.emission_shape = ParticleProcessMaterial.EMISSION_SHAPE_SPHERE
	process.emission_sphere_radius = 0.14
	process.direction = Vector3(0.0, 0.0, 1.0)
	process.spread = 180.0
	process.initial_velocity_min = speed * 0.4
	process.initial_velocity_max = speed
	process.gravity = Vector3(0.0, -0.15, 0.0)
	process.damping_min = 1.4
	process.damping_max = 2.4
	process.scale_min = 0.035
	process.scale_max = 0.095
	process.color = Color("8feaff")
	burst.process_material = process
	var spark := SphereMesh.new()
	spark.radius = 0.055
	spark.height = 0.11
	spark.radial_segments = 6
	spark.rings = 3
	var spark_material := StandardMaterial3D.new()
	spark_material.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	spark_material.albedo_color = Color("a7f2ff")
	spark_material.emission_enabled = true
	spark_material.emission = Color("43caff")
	spark_material.emission_energy_multiplier = 3.2
	spark.material = spark_material
	burst.draw_pass_1 = spark
	burst.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	burst.finished.connect(burst.queue_free)
	add_child(burst)
	burst.emitting = true
	spark_bursts.append(burst)

func _spawn_shock_ring(world_position: Vector3, size: float) -> void:
	if shock_rings.size() >= 8:
		return
	var ring := MeshInstance3D.new()
	ring.name = "3DShockRing"
	var torus := TorusMesh.new()
	torus.inner_radius = 0.035
	torus.outer_radius = 0.065
	torus.rings = 16
	torus.ring_segments = 8
	ring.mesh = torus
	ring.position = world_position
	ring.rotation.x = PI / 2.0
	ring.scale = Vector3.ONE * clampf(size, 0.4, 1.3)
	var ring_material := StandardMaterial3D.new()
	ring_material.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	ring_material.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	ring_material.albedo_color = Color("8feaff", 0.88)
	ring_material.emission_enabled = true
	ring_material.emission = Color("43caff")
	ring_material.emission_energy_multiplier = 2.4
	ring.material_override = ring_material
	ring.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	add_child(ring)
	shock_rings.append({"node": ring, "material": ring_material, "age": 0.0, "scale": ring.scale.x})

func damage_target(target: RigidBody3D, impact_position: Vector3, damage: int, impulse: Vector3) -> bool:
	if not is_instance_valid(target) or target.is_queued_for_deletion() or not target.has_meta("health"):
		return false
	var cells: Array = target.get_meta("voxel_cells", [])
	if not cells.is_empty():
		var local_impact := target.to_local(impact_position)
		var closest_index := 0
		var closest_distance := INF
		for index in range(cells.size()):
			var cell: Dictionary = cells[index]
			var distance: float = cell["position"].distance_squared_to(local_impact)
			if distance < closest_distance:
				closest_distance = distance
				closest_index = index
		cells.remove_at(closest_index)
		target.set_meta("voxel_cells", cells)
		_rebuild_voxel_batches(target)
	target.apply_impulse(impulse.normalized() * 0.08, target.to_local(impact_position))
	var health := int(target.get_meta("health")) - maxi(1, damage)
	target.set_meta("health", health)
	var artwork := target.get_node_or_null("RockArt") as Sprite3D
	if artwork != null:
		var maximum_health := float(target.get_meta("max_health", 1))
		artwork.modulate.a = clampf(0.86 * float(health) / maximum_health, 0.0, 0.86)
	spawn_hit_fx(impact_position)
	if health > 0:
		return false
	var remaining: Array = target.get_meta("voxel_cells", [])
	var base_velocity := target.linear_velocity + impulse.normalized() * 1.8
	var drop_count := mini(VOXEL_DEBRIS_LIMIT, remaining.size())
	for index in range(drop_count):
		var cell: Dictionary = remaining[index]
		var cell_position: Vector3 = target.to_global(cell["position"])
		var cell_size: float = maxf(cell["size"].x, maxf(cell["size"].y, cell["size"].z))
		var outward := (cell_position - impact_position).normalized()
		if outward.length_squared() < 0.01:
			outward = Vector3.UP
		var tint: Color = cell["color"]
		_spawn_voxel_debris(cell_position, base_velocity + outward * rng.randf_range(1.0, 4.0), tint, cell_size * 0.78)
	if drop_count == 0 and target.get_meta("voxel_debris", false):
		_play_effect(smoke_frames, impact_position, 0.34)
	else:
		spawn_destruction_fx(impact_position, 0.62 + remaining.size() * 0.025)
	target.queue_free()
	return true

func _physics_process(delta: float) -> void:
	clock += delta
	spawn_timer -= delta
	for body in orbiters:
		if not is_instance_valid(body) or body.is_queued_for_deletion():
			continue
		var age := float(body.get_meta("age", 0.0)) + delta
		body.set_meta("age", age)
		if body.has_meta("lifetime") and age > float(body.get_meta("lifetime")):
			body.queue_free()
		elif body.position.x < -34:
			body.queue_free()
	for index in range(shock_rings.size() - 1, -1, -1):
		var ring_state: Dictionary = shock_rings[index]
		ring_state["age"] = float(ring_state["age"]) + delta
		var age: float = float(ring_state["age"])
		if age >= 0.58 or not is_instance_valid(ring_state["node"]):
			if is_instance_valid(ring_state["node"]):
				(ring_state["node"] as MeshInstance3D).queue_free()
			shock_rings.remove_at(index)
			continue
		var ring := ring_state["node"] as MeshInstance3D
		ring.scale = Vector3.ONE * (float(ring_state["scale"]) + age * 3.2)
		(ring_state["material"] as StandardMaterial3D).albedo_color.a = 0.88 * (1.0 - age / 0.58)
	orbiters = orbiters.filter(func(body: RigidBody3D) -> bool: return is_instance_valid(body) and not body.is_queued_for_deletion())
	if spawn_timer <= 0.0 and orbiters.size() < 26:
		var candidate := Vector3(30, rng.randf_range(-11, 11), 0)
		var query := PhysicsShapeQueryParameters3D.new()
		var shape := SphereShape3D.new()
		shape.radius = 1.65
		query.shape = shape
		query.transform.origin = candidate
		query.collision_mask = 1 | 2 | WORLD_LAYER
		if get_world_3d().direct_space_state.intersect_shape(query, 1).is_empty():
			make_orbiter(candidate, rng.randf() < 0.26)
		spawn_timer = 2.4
