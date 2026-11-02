extends SceneTree

var failures: Array[String] = []
var check_count := 0

func check(condition: bool, message: String) -> void:
	check_count += 1
	if not condition:
		failures.append(message)
		push_error(message)

func _initialize() -> void:
	var arena_script = load("res://Godot/arena.gd")
	var arena = arena_script.new()
	check(arena.boss_phase_at(0.0) == "ATTACK", "Boss attack phase starts the cycle")
	check(arena.boss_phase_at(6.0) == "SHIELD", "Boss shield phase follows the attack")
	check(arena.boss_phase_at(9.0) == "DAMAGE" and arena.boss_phase_at(13.0) == "ATTACK", "Boss damage phase returns to attack")
	check(arena.boss_damage_amount(2, "SHIELD") == 0, "Boss shield blocks incoming damage")
	check(arena.boss_damage_amount(2, "DAMAGE") == 3, "Boss damage window amplifies incoming damage")
	arena.party_size = 1
	check(is_equal_approx(arena.party_strength_multiplier(), 1.0), "Solo enemies retain their baseline strength")
	var solo_health: Array[int] = []
	var party_health: Array[int] = []
	for mode in range(3):
		arena.difficulty = mode
		solo_health.append(arena.scaled_enemy_health(10))
	arena.party_size = 6
	for mode in range(3):
		arena.difficulty = mode
		party_health.append(arena.scaled_enemy_health(10))
		check(party_health[mode] >= solo_health[mode] and party_health[mode] <= ceili(float(solo_health[mode]) * 1.41), "Party health scales mildly on difficulty %d" % mode)
	arena.difficulty = 1
	check(is_equal_approx(arena.party_strength_multiplier(), 1.4), "Six-player enemy health scaling is capped")
	check(is_equal_approx(arena.party_attack_multiplier(), 1.125), "Six-player enemy attacks scale slightly")
	check(arena.party_pickup_amount() == 2, "Full-party pickup yield receives a small bonus")
	arena.player_health = 1
	arena.grant_pickup("health")
	check(arena.player_health == 3, "Health pickups scale with party size")
	var visual_script = load("res://Godot/visual_slot.gd")
	var slot = visual_script.new()
	slot.configure(load("res://Web/public/assets/ship.webp"), Vector2(7.1, 2.68), null, false, true)
	check(not slot.metallic_frame.visible, "Undamaged hull hides its metallic frame")
	slot.set_damage_fraction(0.75)
	check(slot.metallic_frame.visible, "Metallic frame appears after damage begins")
	slot.set_damage_fraction(1.0)
	check(not slot.metallic_frame.visible, "Repair hides the metallic frame")
	slot.free()
	arena.free()
	if failures.is_empty():
		print("PASS: %d Godot boss, party-scaling, pickup and hull-frame checks" % check_count)
	else:
		printerr("FAIL: %d of %d Godot gameplay checks failed" % [failures.size(), check_count])
	quit(0 if failures.is_empty() else 1)
