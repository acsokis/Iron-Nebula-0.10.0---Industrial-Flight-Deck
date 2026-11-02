extends SceneTree

var failures: Array[String] = []
var check_count := 0

func _initialize() -> void:
	call_deferred("run_checks")

func check(condition: bool, message: String) -> void:
	check_count += 1
	if not condition:
		failures.append(message)
		push_error(message)

func key(code: Key, pressed: bool) -> void:
	var event := InputEventKey.new()
	event.physical_keycode = code
	event.pressed = pressed
	Input.parse_input_event(event)

func run_checks() -> void:
	var loading_scene := load("res://Godot/loading_screen.tscn") as PackedScene
	check(loading_scene != null, "A themed loading screen is the Godot startup scene")
	if loading_scene != null:
		var loading = loading_scene.instantiate()
		loading.auto_start = false
		root.add_child(loading)
		await process_frame
		check(loading.status_label.text == "PREPARING FLIGHT SYSTEMS...", "Loading UI starts with a visible status")
		check(loading.progress_bar.max_value == 100 and loading.overlay.layer == 10, "Themed loading progress displays above the game")
		loading.queue_free()
	var configured_main_scene: String = ProjectSettings.get_setting("application/run/main_scene")
	check(configured_main_scene == "res://Godot/loading_screen.tscn", "Project launches through the loading screen")
	var scene := load("res://Godot/arena.tscn") as PackedScene
	check(scene != null, "Arena scene must load")
	if scene == null:
		quit(1)
		return
	var arena = scene.instantiate()
	root.add_child(arena)
	await process_frame
	check(arena.menu_overlay.visible and paused, "Flight deck opens in a paused, interactive menu")
	check(arena.flight_button.text == "ENTER FLIGHT" and arena.exit_button.text == "EXIT PREVIEW", "Flight deck provides launch and exit actions")
	arena.begin_flight()
	await physics_frame
	check(not paused and not arena.menu_overlay.visible, "Entering flight resumes the simulation")
	check(arena.menu_overlay.get_child(0).get_child(1).get_child(0).get_child(0).get_child(5).text.contains("PRO-ARCADE"), "The default run is explicitly identified as the competitive arcade profile")
	check(arena.combat_hud.score_label.text == "0000000" and arena.combat_hud.weapon_label.text.contains("PULSE"), "The cockpit HUD exposes live score and selected weapon")
	check(arena.combat_hud.health_bar.value == 1.0 and arena.combat_hud.shield_bar.value > 0.0, "Hull and shield state have dedicated readable meters")
	check(arena.combat_hud.reserve_label.text.contains("LIVES  03") and arena.combat_hud.reserve_label.text.contains("CR 00000"), "The cockpit HUD includes remaining lives and credits")
	check(arena.audio_system.streams.size() >= 12 and arena.audio_system.music_player.stream != null, "Godot loads the desktop soundtrack and the complete gameplay sound set")
	check(Engine.max_fps == 244 and ProjectSettings.get_setting("display/window/vsync/vsync_mode") == 0, "The preview targets low-latency frame pacing up to 244 FPS")
	check(not arena.rtx_active and ProjectSettings.get_setting("iron_nebula/rendering/request_rtx") == false, "Raster rendering is the safe default; path tracing requires an explicit opt-in")
	arena.set_upscaling_mode(1)
	check(get_root().scaling_3d_mode == Viewport.SCALING_3D_MODE_FSR and is_equal_approx(get_root().scaling_3d_scale, 0.82), "FSR quality mode uses the native Godot FSR spatial upscaler")
	arena.set_upscaling_mode(0)
	check(arena.pilot is CharacterBody3D, "Flight uses a real 3D physics body")
	check(arena.pilot.has_node("VisualSlot"), "Visual model stays separate from collision")
	var pilot_slot = arena.pilot.get_node("VisualSlot")
	check(pilot_slot.has_node("MetallicFrame"), "Pilot hull has a texture-masked metallic frame")
	if pilot_slot.has_node("MetallicFrame"):
		var frame := pilot_slot.get_node("MetallicFrame") as MeshInstance3D
		var frame_material := frame.material_override as ShaderMaterial
		var hull := pilot_slot.get_node("HullSprite") as MeshInstance3D
		var frame_mesh := frame.mesh as QuadMesh
		check(not frame.visible and frame.position.z < hull.position.z, "Undamaged hull hides its metallic frame")
		check(frame_material != null and frame_material.shader == load("res://Godot/industrial_hull.gdshader"), "Metallic backing uses its panelled alloy shader")
		check(frame_mesh.size.is_equal_approx(Vector2(7.1, 2.68) * 1.2), "Metallic backing follows and slightly extends beyond the hull silhouette")
		pilot_slot.set_damage_fraction(0.75)
		check(frame.visible, "Metallic frame appears as soon as the hull is damaged")
		pilot_slot.set_damage_fraction(1.0)
		check(not frame.visible, "Repair hides the metallic frame again")
	check(arena.background_layers.layer_count() == 4 and arena.backdrops.size() == 3, "Sector scenery has four parallax depths and three panorama tiles")
	check(arena.background_layers.planet_surfaces.size() == 2 and arena.background_layers.planet_cloud_materials.size() == 2 and arena.background_layers.planet_noise_textures.size() == 2, "Sector scenery contains two procedurally textured, atmosphere-shaded 3D planets")
	check(arena.background_layers.planet_surfaces[0].shader == load("res://Godot/planet_surface.gdshader"), "Planets use the generated procedural surface shader")
	check(arena.background_layers.planet_surfaces[0].get_shader_parameter("planetary_map") == arena.background_layers.planet_noise_textures[0], "Planet shaders use pre-generated seamless noise textures instead of per-pixel noise loops")
	var test_boss: CharacterBody3D = arena.make_body("warden", Vector2(5.2, 3.8))
	test_boss.set_meta("boss_name", "WARDEN TEST")
	test_boss.set_meta("health", 50)
	test_boss.set_meta("max_health", 50)
	var phase_shell := MeshInstance3D.new()
	phase_shell.name = "PhaseShield"
	var phase_mesh := SphereMesh.new()
	phase_mesh.radius = 1.0
	phase_shell.mesh = phase_mesh
	var phase_material := StandardMaterial3D.new()
	phase_material.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	phase_material.albedo_color = Color("59cfff", 0.16)
	phase_shell.material_override = phase_material
	test_boss.get_node("VisualSlot").add_child(phase_shell)
	arena.set_boss_phase(test_boss, "SHIELD")
	check(phase_shell.visible and arena.combat_hud.event_label.text.contains("SHIELD"), "Boss shield phases have a visible 3D barrier and readable combat callout")
	arena.set_boss_phase(test_boss, "DAMAGE")
	check(not phase_shell.visible, "The boss barrier clears for the damage window")
	test_boss.queue_free()
	check(arena.space_world.orbiters.size() >= 3, "Procedural space includes a station and physical voxel obstacles")
	var asteroid: RigidBody3D
	for body in arena.space_world.orbiters:
		if body.has_meta("voxel_cells") and not body.get_meta("station", false) and not body.get_meta("voxel_debris", false):
			asteroid = body
			break
	check(asteroid != null, "A shootable voxel asteroid is present")
	var station: RigidBody3D
	for body in arena.space_world.orbiters:
		if body.get_meta("station", false):
			station = body
			break
	check(station != null and Vector2(station.position.x, station.position.y).distance_to(Vector2(15.5, 6.8)) > 10.4, "The foreground station does not obscure the distant planet")
	if asteroid != null:
		var health_before: int = asteroid.get_meta("health")
		var cells_before: int = asteroid.get_meta("voxel_cells").size()
		var rock_art := asteroid.get_node_or_null("RockArt") as Sprite3D
		check(rock_art != null, "Asteroid voxel body carries the original detailed rock artwork")
		check(asteroid.get_node_or_null("VoxelBatch_rock") is MultiMeshInstance3D, "Asteroid fracture cells use one optimized GPU batch")
		check((asteroid.get_node("RockArt") as Sprite3D).material_override.get("transparency") == BaseMaterial3D.TRANSPARENCY_ALPHA, "Asteroid texture translucency reveals its destructible 3D voxel core")
		arena.space_world.damage_target(asteroid, asteroid.global_position, 1, Vector3.LEFT)
		check(int(asteroid.get_meta("health")) == health_before - 1, "Asteroid hits reduce physical-object health")
		check(asteroid.get_meta("voxel_cells").size() < cells_before, "Asteroid hits visibly remove voxel cells")
		if rock_art != null:
			check(rock_art.modulate.a < 0.82, "Asteroid artwork erodes visibly as its voxel hull is damaged")
	check(arena.boss_phase_at(0.0) == "ATTACK" and arena.boss_phase_at(6.0) == "SHIELD" and arena.boss_phase_at(9.0) == "DAMAGE", "Bosses cycle through attack, shield and damage phases")
	check(arena.boss_damage_amount(2, "SHIELD") == 0 and arena.boss_damage_amount(2, "DAMAGE") == 3, "Boss shield blocks shots and damage windows amplify hits")
	arena.party_size = 6
	check(is_equal_approx(arena.party_strength_multiplier(), 1.4) and is_equal_approx(arena.party_attack_multiplier(), 1.125), "Full-party enemy scaling remains bounded")
	check(arena.party_pickup_amount() == 2, "Full-party pickups provide a modest additional resource")
	arena.player_health = 1
	arena.grant_pickup("health")
	check(arena.player_health == 3, "Health pickups scale with the active party size")
	arena.player_shield = 1
	arena.grant_pickup("shield")
	check(arena.player_shield == arena.player_max_shield, "Shield pickups scale with the active party size")
	arena.grant_pickup("credits")
	check(arena.credits == 63, "Party-size credit pickup amounts remain modest and visible")
	check(arena.WEAPONS.size() == 5, "All five primary weapon modes are available")
	check(arena.projectile_mesh.multimesh.mesh is CapsuleMesh, "Projectiles render as elongated, oriented 3D bolts rather than billboard dots")
	for mode in range(arena.WEAPONS.size()):
		arena.select_weapon(mode)
		var before_shots: int = arena.shots.size()
		arena.fire_volley()
		var expected_shots: int = arena.WEAPONS[mode]["angles"].size()
		check(arena.shots.size() - before_shots == expected_shots, "%s fires its expected volley pattern" % arena.WEAPONS[mode]["name"])
		if expected_shots > 0:
			check(arena.shots[before_shots]["damage"] == arena.WEAPONS[mode]["damage"], "%s applies its configured damage" % arena.WEAPONS[mode]["name"])
		arena.shots.clear()
		arena.fire_clock = 0
	arena.shots.resize(arena.SHOT_LIMIT - 1)
	arena.select_weapon(2)
	arena.fire_volley()
	check(arena.shots.size() == arena.SHOT_LIMIT, "Spread volleys respect the bounded projectile pool")
	arena.shots.clear()
	var select_beam := InputEventKey.new()
	select_beam.physical_keycode = KEY_5
	select_beam.pressed = true
	arena._unhandled_key_input(select_beam)
	check(arena.weapon_mode == 4, "Number keys select the matching weapon")
	var select_pulse := InputEventKey.new()
	select_pulse.physical_keycode = KEY_1
	select_pulse.pressed = true
	arena._unhandled_key_input(select_pulse)
	check(arena.weapon_mode == 0, "Pulse remains the default weapon")
	var before: float = arena.pilot.position.x
	key(KEY_D, true)
	for i in range(45):
		await physics_frame
	key(KEY_D, false)
	check(arena.pilot.position.x > before + 4, "Keyboard input moves the pilot smoothly")
	check(is_zero_approx(arena.pilot.position.z), "Pilot remains on the XY flight plane")
	check(arena.pilot.collision_layer == 1 and (arena.pilot.collision_mask & 1) == 0, "Players never physically block other players")
	var friend = arena.make_body("ship", Vector2(7.1, 2.68))
	friend.collision_layer = 1
	friend.collision_mask = 2 | 4 | 8
	friend.position = arena.pilot.position + Vector3(4, 0, 0)
	for i in range(30):
		await physics_frame
		friend.velocity = Vector3(-25, 0, 0)
		friend.move_and_slide()
	check(friend.position.x < arena.pilot.position.x - 3, "Real Jolt movement allows friendly players to cross")
	friend.queue_free()
	check(not arena.enemies.is_empty(), "Enemy spawn creates a physics target")
	if not arena.enemies.is_empty():
		var enemy_slot = arena.enemies[0].get_node("VisualSlot")
		check(enemy_slot.has_node("MetallicFrame") and not enemy_slot.get_node("MetallicFrame").visible, "Undamaged enemy hull hides its matching metallic frame")
		enemy_slot.set_damage_fraction(0.5)
		check(enemy_slot.get_node("MetallicFrame").visible, "Enemy metallic frame appears when damage begins")
		arena.enemies[0].position = arena.pilot.position + Vector3(8, 0, 0)
	for body in arena.space_world.orbiters:
		body.position = Vector3(0, 45, 0)
		body.collision_layer = 0
	for enemy in arena.enemies:
		enemy.collision_layer = 0
	if asteroid != null:
		asteroid.position = arena.pilot.position + Vector3(13, 0, 0)
		asteroid.linear_velocity = Vector3.ZERO
		asteroid.collision_layer = 4
	await physics_frame
	var asteroid_health_before_shots: int = int(asteroid.get_meta("health")) if asteroid != null else 0
	var asteroid_cells_before_shots: int = asteroid.get_meta("voxel_cells").size() if asteroid != null else 0
	key(KEY_SPACE, true)
	for i in range(36):
		await physics_frame
	key(KEY_SPACE, false)
	if asteroid != null:
		check(int(asteroid.get_meta("health")) < asteroid_health_before_shots, "A swept player shot damages a physical asteroid")
		check(asteroid.get_meta("voxel_cells").size() < asteroid_cells_before_shots, "Player fire removes asteroid voxels")
		arena.space_world.damage_target(asteroid, asteroid.global_position, 100, Vector3.LEFT)
		await process_frame
		var fracture_count := 0
		for body in arena.space_world.orbiters:
			if body.has_meta("voxel_debris") and body.get_meta("voxel_debris"):
				var shard := body.get_node_or_null("FractureShard") as MeshInstance3D
				if shard != null and shard.mesh is PrismMesh:
					fracture_count += 1
		check(fracture_count > 0, "Destroyed asteroids shed spinning, collidable low-poly fracture shards")
		check(not arena.space_world.spark_bursts.is_empty() and not arena.space_world.shock_rings.is_empty(), "Destruction adds bounded GPU sparks and a real 3D expanding shock ring")
	if not arena.enemies.is_empty():
		var ray_target: CharacterBody3D = arena.enemies[0]
		ray_target.collision_layer = 2
		key(KEY_SPACE, true)
		for i in range(90):
			if is_instance_valid(ray_target) and not ray_target.is_queued_for_deletion():
				ray_target.position = arena.pilot.position + Vector3(8, 0, 0)
			await physics_frame
		key(KEY_SPACE, false)
	check(arena.shots.size() > 0, "Firing creates live projectiles")
	check(arena.shots.size() <= arena.SHOT_LIMIT, "Projectile storage remains bounded")
	check(arena.score > 0, "Swept 3D projectile queries hit spawned enemies (score %d, live shots %d)" % [arena.score, arena.shots.size()])
	check(arena.projectile_mesh.multimesh.visible_instance_count == arena.shots.size(), "GPU batch matches live projectile count")
	for sector in range(3):
		arena.set_sector(sector)
		await process_frame
		check(arena.sector == sector and arena.backdrops.size() == 3 and arena.background_layers.sector == sector and arena.space_world.sector == sector, "Every sector updates its panorama and world palette")
	var model := Node3D.new()
	model.name = "ImportedModel"
	var packed := PackedScene.new()
	check(packed.pack(model) == OK, "Replacement visual scene packs")
	model.free()
	var slot = arena.pilot.get_node("VisualSlot")
	slot.configure(arena.art("ship"), Vector2.ONE, packed)
	await process_frame
	check(slot.has_node("ImportedModel"), "A model scene replaces the sprite without replacing the pilot body")
	check(not slot.has_node("MetallicFrame"), "Imported 3D ship models do not receive a sprite frame")
	check(arena.pilot.has_node("Muzzle"), "Weapon mount survives visual replacement")
	key(KEY_D, true)
	for i in range(150):
		await physics_frame
	key(KEY_D, false)
	check(arena.pilot.position.x < 23, "Solid world boundaries stop the pilot without transform clamping")
	check(not arena.spawn_is_clear(arena.pilot.position, Vector2(7.1, 2.68)), "Spawner rejects occupied full-body volume")
	arena.player_shield = 0
	arena.player_health = 1
	arena.player_lives = 1
	arena.player_invulnerability = 0.0
	arena.damage_player()
	check(arena.game_over and arena.menu_overlay.visible and arena.flight_button.text == "START NEW RUN", "The final lost life ends a competitive run and offers a restart")
	arena.begin_flight()
	check(not arena.game_over and arena.player_lives == 3 and arena.player_health == arena.player_max_health and arena.player_shield == arena.player_max_shield and arena.score == 0 and arena.credits == 0 and not paused, "Restart resets score-attack resources and resumes a fresh run")
	arena.audio_system.start_music()
	arena.audio_system.stop_all()
	check(not arena.audio_system.music_player.playing and arena.audio_system.streams.is_empty(), "Audio playback and stream references can be released for clean shutdown")
	if failures.is_empty():
		print("PASS: %d Godot checks (loading, menu, parallax, voxel damage, weapons, metallic hull frames, physics and model replacement)" % check_count)
	else:
		printerr("FAIL: %d of %d Godot checks failed" % [failures.size(), check_count])
	arena.queue_free()
	await process_frame
	await create_timer(0.25).timeout
	quit(0 if failures.is_empty() else 1)
