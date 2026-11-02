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
	check(arena.pilot is CharacterBody3D, "Flight uses a real 3D physics body")
	check(arena.pilot.has_node("VisualSlot"), "Visual model stays separate from collision")
	var pilot_slot = arena.pilot.get_node("VisualSlot")
	check(pilot_slot.has_node("MetallicFrame"), "Pilot hull has a texture-masked metallic frame")
	if pilot_slot.has_node("MetallicFrame"):
		var frame := pilot_slot.get_node("MetallicFrame") as MeshInstance3D
		var frame_material := frame.material_override as StandardMaterial3D
		var hull := pilot_slot.get_node("HullSprite") as MeshInstance3D
		var frame_mesh := frame.mesh as QuadMesh
		check(not frame.visible and frame.position.z < hull.position.z and frame_material.metallic > 0.9, "Undamaged hull hides its metallic frame")
		check(frame_material.albedo_texture == arena.art("ship") and frame_mesh.size.is_equal_approx(Vector2(7.1, 2.68) * 1.08), "Metallic backing follows the hull texture and silhouette")
		pilot_slot.set_damage_fraction(0.75)
		check(frame.visible, "Metallic frame appears as soon as the hull is damaged")
		pilot_slot.set_damage_fraction(1.0)
		check(not frame.visible, "Repair hides the metallic frame again")
	check(arena.boss_phase_at(0.0) == "ATTACK" and arena.boss_phase_at(6.0) == "SHIELD" and arena.boss_phase_at(9.0) == "DAMAGE", "Bosses cycle through attack, shield and damage phases")
	check(arena.boss_damage_amount(2, "SHIELD") == 0 and arena.boss_damage_amount(2, "DAMAGE") == 3, "Boss shield blocks shots and damage windows amplify hits")
	arena.party_size = 6
	check(is_equal_approx(arena.party_strength_multiplier(), 1.4) and is_equal_approx(arena.party_attack_multiplier(), 1.125), "Full-party enemy scaling remains bounded")
	check(arena.party_pickup_amount() == 2, "Full-party pickups provide a modest additional resource")
	arena.player_health = 1
	arena.grant_pickup("health")
	check(arena.player_health == 3, "Health pickups scale with the active party size")
	check(arena.WEAPONS.size() == 5, "All five primary weapon modes are available")
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
	key(KEY_SPACE, true)
	for i in range(150):
		await physics_frame
	key(KEY_SPACE, false)
	check(arena.shots.size() > 0, "Firing creates live projectiles")
	check(arena.shots.size() <= arena.SHOT_LIMIT, "Projectile storage remains bounded")
	check(arena.score > 0, "Swept 3D projectile queries hit spawned enemies")
	check(arena.projectile_mesh.multimesh.visible_instance_count == arena.shots.size(), "GPU batch matches live projectile count")
	for sector in range(3):
		arena.set_sector(sector)
		await process_frame
		check(arena.sector == sector and arena.backdrops.size() == 3, "Every sector retains three endless tiles")
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
	if failures.is_empty():
		print("PASS: %d Godot checks (themed loading, five weapons, metallic hull frames, physics hits, GPU bounds and model replacement)" % check_count)
	else:
		printerr("FAIL: %d of %d Godot checks failed" % [failures.size(), check_count])
	arena.queue_free()
	await process_frame
	quit(0 if failures.is_empty() else 1)
