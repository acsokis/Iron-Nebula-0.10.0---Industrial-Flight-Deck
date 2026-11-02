extends Node3D

const SEED_VALUE = 87321
const VOXEL_DEBRIS_LIMIT = 12
const EFFECT_LIMIT = 36
const WORLD_LAYER = 4
var rng := RandomNumberGenerator.new()
var orbiters: Array[RigidBody3D] = []
var effects: Array[AnimatedSprite3D] = []
var clock := 0.0
var spawn_timer := 0.0
var smoke_frames: SpriteFrames
var explosion_frames: SpriteFrames
var sector := 0

func _ready() -> void:
	rng.seed = int(ProjectSettings.get_setting("iron_nebula/world/seed", SEED_VALUE))
	_build_effect_frames()
	make_station(Vector3(11, 6, 0))
	var reservations: Array[Vector3] = [Vector3(11, 6, 0), Vector3(-13, 0, 0)]
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
			if not is_instance_valid(cell) or not cell.get_meta("signal_accent", false):
				continue
			var voxel_mesh := cell.mesh as PrimitiveMesh
			if voxel_mesh != null:
				voxel_mesh.material = material(accent_color, true, float(cell.get_meta("metalness", 0.82)))
				cell.set_meta("voxel_color", accent_color)

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
	body.set_meta("age", 0.0)
	add_child(body)
	orbiters.append(body)
	return body

func _add_voxel(body: RigidBody3D, local_position: Vector3, size: Vector3, color: Color, accent: bool = false, rounded: bool = false, metalness: float = 0.18) -> void:
	var cell := MeshInstance3D.new()
	if rounded:
		var rock := SphereMesh.new()
		rock.radius = maxf(size.x, maxf(size.y, size.z)) * 0.56
		rock.height = rock.radius * 1.8
		rock.radial_segments = 6
		rock.rings = 3
		rock.material = material(color, accent, metalness)
		cell.mesh = rock
	else:
		var cube := BoxMesh.new()
		cube.size = size
		cube.material = material(color, accent, metalness)
		cell.mesh = cube
	cell.position = local_position
	cell.gi_mode = GeometryInstance3D.GI_MODE_DYNAMIC
	cell.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_ON
	cell.set_meta("voxel_size", maxf(size.x, maxf(size.y, size.z)))
	cell.set_meta("voxel_color", color)
	cell.set_meta("signal_accent", accent)
	cell.set_meta("metalness", metalness)
	body.add_child(cell)
	var cells: Array = body.get_meta("voxel_cells", [])
	cells.append(cell)
	body.set_meta("voxel_cells", cells)

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
	var artwork := Sprite3D.new()
	artwork.name = "RockArt"
	artwork.texture = load("res://Web/public/assets/%s.webp" % ("rock" if wreck else "rock2")) as Texture2D
	artwork.pixel_size = 0.01
	artwork.scale = Vector3.ONE * radius * 0.39
	artwork.position.z = 1.25
	artwork.modulate = Color(1.0, 1.0, 1.0, 0.94)
	artwork.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	var artwork_material := StandardMaterial3D.new()
	artwork_material.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	artwork_material.albedo_texture = artwork.texture
	artwork_material.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA_SCISSOR
	artwork_material.alpha_scissor_threshold = 0.025
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

func _spawn_voxel_debris(world_position: Vector3, local_cell: Vector3, velocity: Vector3, color: Color, scale: float) -> void:
	if orbiters.size() >= 42:
		return
	var chunk := _new_body("VoxelDebris", world_position, 1, 0.45)
	var size := maxf(0.12, scale)
	_add_voxel(chunk, Vector3.ZERO, Vector3.ONE * size, color, false, true, 0.06)
	var shape := BoxShape3D.new()
	shape.size = Vector3.ONE * size
	_add_collision(chunk, shape)
	chunk.collision_mask = 1 | 2
	chunk.position += local_cell
	chunk.set_meta("voxel_debris", true)
	chunk.set_meta("lifetime", 8.0)
	chunk.linear_velocity = velocity
	chunk.angular_velocity.z = rng.randf_range(-2.2, 2.2)

func damage_target(target: RigidBody3D, impact_position: Vector3, damage: int, impulse: Vector3) -> bool:
	if not is_instance_valid(target) or target.is_queued_for_deletion() or not target.has_meta("health"):
		return false
	var cells: Array = target.get_meta("voxel_cells", [])
	if not cells.is_empty():
		var local_impact := target.to_local(impact_position)
		var closest_index := 0
		var closest_distance := INF
		for index in range(cells.size()):
			var cell := cells[index] as MeshInstance3D
			if not is_instance_valid(cell) or cell.is_queued_for_deletion():
				continue
			var distance := cell.position.distance_squared_to(local_impact)
			if distance < closest_distance:
				closest_distance = distance
				closest_index = index
		var removed := cells.pop_at(closest_index) as MeshInstance3D
		if is_instance_valid(removed):
			removed.queue_free()
		target.set_meta("voxel_cells", cells)
	target.apply_impulse(impulse.normalized() * 0.08, target.to_local(impact_position))
	var health := int(target.get_meta("health")) - maxi(1, damage)
	target.set_meta("health", health)
	var artwork := target.get_node_or_null("RockArt") as Sprite3D
	if artwork != null:
		var maximum_health := float(target.get_meta("max_health", 1))
		artwork.modulate.a = clampf(0.28 + 0.72 * float(health) / maximum_health, 0.0, 1.0)
	spawn_hit_fx(impact_position)
	if health > 0:
		return false
	var remaining: Array = target.get_meta("voxel_cells", [])
	var base_velocity := target.linear_velocity + impulse.normalized() * 1.8
	var drop_count := mini(VOXEL_DEBRIS_LIMIT, remaining.size())
	for index in range(drop_count):
		var cell := remaining[index] as MeshInstance3D
		if not is_instance_valid(cell) or cell.is_queued_for_deletion():
			continue
		var cell_position := target.to_global(cell.position)
		var cell_size := float(cell.get_meta("voxel_size", 0.3))
		var outward := (cell_position - impact_position).normalized()
		if outward.length_squared() < 0.01:
			outward = Vector3.UP
		var tint: Color = cell.get_meta("voxel_color", Color("65747c"))
		_spawn_voxel_debris(cell_position, Vector3.ZERO, base_velocity + outward * rng.randf_range(1.0, 4.0), tint, cell_size * 0.78)
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
