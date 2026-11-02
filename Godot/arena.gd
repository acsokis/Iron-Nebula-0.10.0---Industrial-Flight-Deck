extends Node3D

## Playable migration foundation, not yet a campaign/co-op replacement.
@export var ship_model: PackedScene
const VisualSlot = preload("res://Godot/visual_slot.gd")
const FlightNavigation = preload("res://Godot/flight_navigation.gd")
const ProceduralSpace = preload("res://Godot/procedural_space.gd")
const BackgroundLayers = preload("res://Godot/background_layers.gd")
const BACKDROPS = ["spaceFrontier", "spaceRift", "spaceInferno"]
const FIELD = Vector2(48, 27)
const SHOT_LIMIT = 512
const PARTY_LIMIT = 6
const DIFFICULTY_HEALTH = [0.78, 1.0, 1.32]
const DIFFICULTY_FIRE_RATE = [0.9, 1.0, 1.1]
const WEAPONS := [
	{"name": "PULSE", "interval": 0.10, "speed": 38.0, "damage": 1, "angles": [0.0], "scale": Vector3.ONE},
	{"name": "LANCE", "interval": 0.32, "speed": 52.0, "damage": 2, "angles": [0.0], "scale": Vector3(1.8, 0.75, 0.75)},
	{"name": "ARC", "interval": 0.24, "speed": 34.0, "damage": 1, "angles": [-0.14, 0.0, 0.14], "scale": Vector3(0.8, 0.8, 0.8)},
	{"name": "GATLING", "interval": 0.055, "speed": 43.0, "damage": 1, "angles": [0.0], "scale": Vector3(0.65, 0.65, 0.65)},
	{"name": "BEAM", "interval": 0.14, "speed": 56.0, "damage": 3, "angles": [0.0], "scale": Vector3(2.4, 0.55, 0.55)},
]
var camera: Camera3D
var pilot: CharacterBody3D
var muzzle: Marker3D
var environment: Environment
var status: Label
var menu_overlay: CanvasLayer
var flight_button: Button
var exit_button: Button
var background_layers
var space_world
var backdrops: Array[Node3D] = []
var shots: Array[Dictionary] = []
var enemy_shots: Array[Dictionary] = []
var pickups: Array[Dictionary] = []
var enemies: Array[CharacterBody3D] = []
var projectile_mesh: MultiMeshInstance3D
var enemy_projectile_mesh: MultiMeshInstance3D
var elapsed := 0.0
var fire_clock := 0.0
var spawn_clock := 0.0
var weapon_mode := 0
var sector := 0
var score := 0
var party_size := 1
var difficulty := 1
var player_health := 4
var player_max_health := 4
var player_shield := 2
var player_max_shield := 3
var player_invulnerability := 0.0
var player_weapon_level := 1
var miniboss_spawned := false
var boss_spawned := false
var tethered := true
var rtx_active := false
var navigation = FlightNavigation.new()

func art(name: String) -> Texture2D:
	return load("res://Web/public/assets/%s.webp" % name) as Texture2D

func parse_run_options() -> void:
	for argument in OS.get_cmdline_user_args():
		if argument.begins_with("--party-size="):
			party_size = clampi(int(argument.trim_prefix("--party-size=")), 1, PARTY_LIMIT)
		elif argument.begins_with("--difficulty="):
			difficulty = clampi(int(argument.trim_prefix("--difficulty=")), 0, 2)

func party_strength_multiplier() -> float:
	return 1.0 + 0.08 * (party_size - 1)

func party_attack_multiplier() -> float:
	return 1.0 + 0.025 * (party_size - 1)

func party_pickup_amount(base_amount: int = 1) -> int:
	return base_amount + int((party_size - 1) / 4)

func boss_phase_at(phase_age: float) -> String:
	var phase_time := fposmod(maxf(0.0, phase_age), 13.0)
	if phase_time < 6.0:
		return "ATTACK"
	if phase_time < 9.0:
		return "SHIELD"
	return "DAMAGE"

func boss_damage_amount(damage: int, phase: String) -> int:
	if phase == "SHIELD":
		return 0
	return ceili(float(damage) * (1.5 if phase == "DAMAGE" else 1.0))

func _ready() -> void:
	parse_run_options()
	camera = Camera3D.new()
	camera.projection = Camera3D.PROJECTION_PERSPECTIVE
	camera.fov = rad_to_deg(2 * atan(FIELD.y / 120))
	camera.position = Vector3(0, 0, 60)
	add_child(camera)
	camera.current = true
	environment = Environment.new()
	environment.background_mode = Environment.BG_COLOR
	environment.background_color = Color("030715")
	environment.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
	environment.ambient_light_color = Color("8fa4be")
	environment.ambient_light_energy = 0.6
	environment.tonemap_mode = Environment.TONE_MAPPER_ACES
	environment.glow_enabled = true
	var world_environment := WorldEnvironment.new()
	world_environment.environment = environment
	add_child(world_environment)
	configure_rtx()
	var light := OmniLight3D.new()
	light.position = Vector3(-6, 5, 8)
	light.light_color = Color("69dfff")
	light.light_energy = 6
	light.omni_range = 36
	add_child(light)
	background_layers = BackgroundLayers.new()
	background_layers.name = "BackgroundLayers"
	add_child(background_layers)
	for tile in background_layers.panorama_tiles:
		backdrops.append(tile)
	set_sector(0)
	pilot = make_body("ship", Vector2(7.1, 2.68), ship_model)
	pilot.collision_layer = 1
	pilot.collision_mask = 2 | 4 | 8
	pilot.position.x = -13
	make_boundary(Vector3(0, 14.5, 0), Vector3(70, 2, 8), 4)
	make_boundary(Vector3(0, -14.5, 0), Vector3(70, 2, 8), 4)
	make_boundary(Vector3(-33, 0, 0), Vector3(2, 30, 8), 4)
	make_boundary(Vector3(33, 0, 0), Vector3(2, 30, 8), 4)
	# Player-only screen boundaries let enemies enter from outside the viewport.
	make_boundary(Vector3(-25, 0, 0), Vector3(2, 30, 8), 8)
	make_boundary(Vector3(25, 0, 0), Vector3(2, 30, 8), 8)
	space_world = ProceduralSpace.new()
	space_world.name = "ProceduralSpace"
	add_child(space_world)
	if not rtx_active and RenderingServer.get_current_rendering_method() == "forward_plus" and ResourceLoader.exists("res://Godot/space_gi.res"):
		var gi := VoxelGI.new()
		gi.size = Vector3(64, 28, 12)
		gi.data = load("res://Godot/space_gi.res") as VoxelGIData
		add_child(gi)
		print("Iron Nebula raster VoxelGI: baked station volume active")
	muzzle = Marker3D.new()
	muzzle.name = "Muzzle"
	muzzle.position.x = 3.2
	pilot.add_child(muzzle)
	projectile_mesh = create_projectile_batch(Color("43caff"))
	add_child(projectile_mesh)
	enemy_projectile_mesh = create_projectile_batch(Color("ff785d"))
	add_child(enemy_projectile_mesh)
	var hud := CanvasLayer.new()
	add_child(hud)
	status = Label.new()
	status.position = Vector2(28, 24)
	status.add_theme_font_size_override("font_size", 24)
	status.add_theme_color_override("font_color", Color("b8f1ff"))
	status.add_theme_color_override("font_shadow_color", Color(0.0, 0.04, 0.09, 0.9))
	status.add_theme_constant_override("shadow_offset_x", 2)
	status.add_theme_constant_override("shadow_offset_y", 2)
	hud.add_child(status)
	_build_flight_menu()
	if "--capture-preview" in OS.get_cmdline_user_args() or "--capture-flight-preview" in OS.get_cmdline_user_args():
		capture_preview.call_deferred()

func _build_flight_menu() -> void:
	menu_overlay = CanvasLayer.new()
	menu_overlay.name = "FlightDeckMenu"
	menu_overlay.layer = 20
	menu_overlay.process_mode = Node.PROCESS_MODE_ALWAYS
	add_child(menu_overlay)
	var fill := Control.new()
	fill.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	menu_overlay.add_child(fill)
	var shade := ColorRect.new()
	shade.color = Color(0.008, 0.022, 0.04, 0.82)
	shade.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	fill.add_child(shade)
	var center := CenterContainer.new()
	center.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	fill.add_child(center)
	var panel := PanelContainer.new()
	panel.custom_minimum_size = Vector2(650, 430)
	panel.add_theme_stylebox_override("panel", _flight_panel_style())
	center.add_child(panel)
	var content := VBoxContainer.new()
	content.add_theme_constant_override("separation", 14)
	panel.add_child(content)
	var eyebrow := Label.new()
	eyebrow.text = "FLIGHT DECK   /   OPERATIONS CONTROL"
	eyebrow.add_theme_color_override("font_color", Color("53ddff"))
	eyebrow.add_theme_font_size_override("font_size", 13)
	content.add_child(eyebrow)
	var title := Label.new()
	title.text = "IRON NEBULA"
	title.add_theme_color_override("font_color", Color("edf7fb"))
	title.add_theme_font_size_override("font_size", 38)
	content.add_child(title)
	var summary := Label.new()
	summary.text = "EXPEDITION SYSTEMS   ·   SECTOR TRANSIT   ·   FLIGHT READY"
	summary.add_theme_color_override("font_color", Color("8ba3b1"))
	summary.add_theme_font_size_override("font_size", 13)
	content.add_child(summary)
	var divider := ColorRect.new()
	divider.custom_minimum_size.y = 1
	divider.color = Color("1f5567")
	content.add_child(divider)
	var selectors := GridContainer.new()
	selectors.columns = 2
	selectors.add_theme_constant_override("h_separation", 18)
	selectors.add_theme_constant_override("v_separation", 12)
	content.add_child(selectors)
	var sector_label := Label.new()
	sector_label.text = "DESTINATION"
	sector_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	sector_label.add_theme_color_override("font_color", Color("b8ced8"))
	selectors.add_child(sector_label)
	var sector_select := OptionButton.new()
	sector_select.add_item("FRONTIER")
	sector_select.add_item("RIFT")
	sector_select.add_item("INFERNO")
	sector_select.select(sector)
	sector_select.item_selected.connect(_on_sector_selected)
	selectors.add_child(sector_select)
	var difficulty_label := Label.new()
	difficulty_label.text = "FLIGHT PROFILE"
	difficulty_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	difficulty_label.add_theme_color_override("font_color", Color("b8ced8"))
	selectors.add_child(difficulty_label)
	var difficulty_select := OptionButton.new()
	difficulty_select.add_item("ASSISTED")
	difficulty_select.add_item("STANDARD")
	difficulty_select.add_item("VETERAN")
	difficulty_select.select(difficulty)
	difficulty_select.item_selected.connect(_on_difficulty_selected)
	selectors.add_child(difficulty_select)
	var mission := Label.new()
	mission.text = "MISSION 01   /   SYSTEMS CHECK\nMovement  WASD · left stick     Fire  mouse · Space · RT\nWeapons  1–5     Sector map  Tab     Flight deck  Esc"
	mission.add_theme_color_override("font_color", Color("95acb8"))
	mission.add_theme_font_size_override("font_size", 13)
	mission.add_theme_constant_override("line_spacing", 5)
	content.add_child(mission)
	flight_button = Button.new()
	flight_button.text = "ENTER FLIGHT"
	flight_button.custom_minimum_size.y = 52
	flight_button.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	flight_button.add_theme_font_size_override("font_size", 17)
	flight_button.add_theme_color_override("font_color", Color("031018"))
	flight_button.add_theme_stylebox_override("normal", _flight_button_style(Color("53ddff")))
	flight_button.add_theme_stylebox_override("hover", _flight_button_style(Color("a0efff")))
	flight_button.add_theme_stylebox_override("pressed", _flight_button_style(Color("36bcd9")))
	flight_button.pressed.connect(begin_flight)
	content.add_child(flight_button)
	exit_button = Button.new()
	exit_button.text = "EXIT PREVIEW"
	exit_button.custom_minimum_size.y = 42
	exit_button.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	exit_button.add_theme_color_override("font_color", Color("b8ced8"))
	exit_button.add_theme_stylebox_override("normal", _flight_button_style(Color("132330")))
	exit_button.add_theme_stylebox_override("hover", _flight_button_style(Color("203a49")))
	exit_button.pressed.connect(_quit_preview)
	content.add_child(exit_button)
	var footer := Label.new()
	footer.text = "PREVIEW BUILD   ·   NO NETWORK CO-OP IN THIS ENGINE VIEW"
	footer.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	footer.add_theme_color_override("font_color", Color("617682"))
	footer.add_theme_font_size_override("font_size", 11)
	content.add_child(footer)
	get_tree().paused = true

func _flight_panel_style() -> StyleBoxFlat:
	var style := StyleBoxFlat.new()
	style.bg_color = Color("06111d")
	style.border_color = Color("28576b")
	style.set_border_width_all(1)
	style.set_corner_radius_all(3)
	style.content_margin_left = 34
	style.content_margin_right = 34
	style.content_margin_top = 30
	style.content_margin_bottom = 26
	return style

func _flight_button_style(color: Color) -> StyleBoxFlat:
	var style := StyleBoxFlat.new()
	style.bg_color = color
	style.border_color = color.lightened(0.12)
	style.set_border_width_all(1)
	style.set_corner_radius_all(2)
	style.content_margin_left = 16
	style.content_margin_right = 16
	style.content_margin_top = 10
	style.content_margin_bottom = 10
	return style

func _on_sector_selected(value: int) -> void:
	set_sector(value)

func _on_difficulty_selected(value: int) -> void:
	difficulty = clampi(value, 0, DIFFICULTY_HEALTH.size() - 1)

func begin_flight() -> void:
	get_tree().paused = false
	menu_overlay.visible = false

func _quit_preview() -> void:
	get_tree().quit()

func show_flight_menu() -> void:
	flight_button.text = "RESUME FLIGHT"
	menu_overlay.visible = true
	get_tree().paused = true

func create_projectile_batch(glow: Color) -> MultiMeshInstance3D:
	var instance := MultiMeshInstance3D.new()
	var mesh := SphereMesh.new()
	mesh.radius = 0.12
	mesh.height = 0.24
	var material := StandardMaterial3D.new()
	material.albedo_color = Color("96ecff")
	material.emission_enabled = true
	material.emission = glow
	material.emission_energy_multiplier = 4
	mesh.material = material
	var batch := MultiMesh.new()
	batch.transform_format = MultiMesh.TRANSFORM_3D
	batch.mesh = mesh
	batch.instance_count = SHOT_LIMIT
	batch.visible_instance_count = 0
	instance.multimesh = batch
	return instance

func capture_preview() -> void:
	var flight_capture := "--capture-flight-preview" in OS.get_cmdline_user_args()
	if flight_capture:
		begin_flight()
	Input.warp_mouse(Vector2(16, 704))
	Input.set_mouse_mode(Input.MOUSE_MODE_HIDDEN)
	for i in range(60):
		await RenderingServer.frame_post_draw
	var image := get_viewport().get_texture().get_image()
	var path := "res://.godot/engine-flight-preview.png" if flight_capture else "res://.godot/engine-preview.png"
	if "--raster-preview" in OS.get_cmdline_user_args():
		path = "res://.godot/engine-flight-preview-raster.png" if flight_capture else "res://.godot/engine-preview-raster.png"
	var result := image.save_png(path)
	print("Engine viewport capture: %s" % error_string(result))

func configure_rtx() -> void:
	# NVIDIA fork properties are discovered dynamically, so stock Godot can still
	# run this scene. No fictional Vortex plugin or unbaked VoxelGI is advertised.
	var rd := RenderingServer.get_rendering_device()
	var fork_available := false
	for property in environment.get_property_list():
		if property.name == "pathtracing_enabled":
			fork_available = true
	rtx_active = fork_available and rd != null and rd.has_feature(12) and bool(ProjectSettings.get_setting("iron_nebula/rendering/request_rtx", true)) and not "--raster-preview" in OS.get_cmdline_user_args()
	if fork_available:
		# DLSS runtime libraries are a separate vendor dependency. Use the explicit
		# supported NONE denoiser until their availability is validated.
		environment.set("pathtracing_denoiser", 0)
		environment.set("pathtracing_enabled", rtx_active)
	print("Iron Nebula engine preview: renderer=%s, NVIDIA fork=%s, RTX active=%s, denoiser=NONE" % [RenderingServer.get_current_rendering_method(), fork_available, rtx_active])

func make_body(texture: String, dimensions: Vector2, model: PackedScene = null, mirror: bool = false) -> CharacterBody3D:
	var body := CharacterBody3D.new()
	body.motion_mode = CharacterBody3D.MOTION_MODE_FLOATING
	body.axis_lock_linear_z = true
	body.collision_layer = 2
	body.collision_mask = 1 | 2 | 4
	var collision := CollisionShape3D.new()
	var shape := CapsuleShape3D.new()
	shape.radius = dimensions.y * 0.36
	shape.height = maxf(dimensions.x * 0.84, shape.radius * 2)
	collision.shape = shape
	collision.rotation.z = PI / 2
	body.add_child(collision)
	var visual := VisualSlot.new()
	visual.name = "VisualSlot"
	visual.configure(art(texture), dimensions, model, mirror, true)
	body.add_child(visual)
	add_child(body)
	return body

func make_boundary(center: Vector3, size: Vector3, layer: int) -> void:
	var wall := StaticBody3D.new()
	wall.collision_layer = layer
	wall.collision_mask = 0
	wall.position = center
	var collision := CollisionShape3D.new()
	var shape := BoxShape3D.new()
	shape.size = size
	collision.shape = shape
	wall.add_child(collision)
	add_child(wall)

func select_weapon(value: int) -> void:
	weapon_mode = posmod(value, WEAPONS.size())

func fire_volley() -> void:
	var weapon: Dictionary = WEAPONS[weapon_mode]
	for angle: float in weapon["angles"]:
		if shots.size() >= SHOT_LIMIT:
			break
		var direction := Vector3(cos(angle), sin(angle), 0)
		shots.append({
			"position": muzzle.global_position,
			"velocity": direction * float(weapon["speed"]),
			"damage": int(weapon["damage"]) + player_weapon_level - 1,
			"scale": weapon["scale"],
		})
	fire_clock = float(weapon["interval"])

func scaled_enemy_health(base_health: int) -> int:
	return maxi(1, ceili(float(base_health) * DIFFICULTY_HEALTH[difficulty] * party_strength_multiplier()))

func spawn_boss(miniboss: bool) -> CharacterBody3D:
	var texture: String = "warden" if miniboss else String(["sentinel", "riftGuardian", "infernoGuardian"][sector])
	var size := Vector2(5.2, 3.8) if miniboss else Vector2(7.5, 5.3)
	var center := Vector3(26.0, 0.0, 0.0)
	if not spawn_is_clear(center, size):
		return null
	var enemy := make_body(texture, size, null, true)
	enemy.position = center
	enemy.set_meta("boss", true)
	enemy.set_meta("boss_name", "WARDEN" if miniboss else ["SENTINEL", "RIFT GUARDIAN", "INFERNO GUARDIAN"][sector])
	enemy.set_meta("health", scaled_enemy_health(70 if miniboss else 145))
	enemy.set_meta("max_health", int(enemy.get_meta("health")))
	enemy.set_meta("phase", "ATTACK")
	enemy.set_meta("phase_age", 0.0)
	enemy.set_meta("fire_clock", 1.2)
	enemies.append(enemy)
	return enemy

func spawn_enemy_projectile(enemy: CharacterBody3D, boss: bool) -> void:
	if enemy_shots.size() >= SHOT_LIMIT:
		enemy_shots.pop_front()
	var direction := (pilot.position - enemy.position).normalized()
	if direction.length_squared() < 0.01:
		direction = Vector3.LEFT
	var speed: float = (12.0 if boss else 9.0) * party_attack_multiplier() * [0.88, 1.0, 1.12][difficulty]
	enemy_shots.append({"position": enemy.position + Vector3(-1.6, 0, 0), "velocity": direction * speed})

func damage_player() -> void:
	if player_invulnerability > 0.0:
		return
	player_invulnerability = 0.75 if player_shield > 0 else 1.4
	if player_shield > 0:
		player_shield -= 1
	else:
		player_health -= 1
	if player_health <= 0:
		player_health = player_max_health
		player_shield = player_max_shield
		pilot.position = Vector3(-13, 0, 0)
		player_invulnerability = 2.5

func spawn_pickup(position: Vector3, kind: String) -> void:
	var pickup := MeshInstance3D.new()
	var mesh := SphereMesh.new()
	mesh.radius = 0.36
	mesh.height = 0.72
	var material := StandardMaterial3D.new()
	var color: Color = {"health": Color("ff796e"), "shield": Color("67ddff"), "weapon": Color("ffd66e"), "credits": Color("96f28b")}.get(kind, Color.WHITE)
	material.albedo_color = color
	material.emission_enabled = true
	material.emission = color
	material.emission_energy_multiplier = 2.5
	mesh.material = material
	pickup.mesh = mesh
	pickup.position = position
	add_child(pickup)
	pickups.append({"node": pickup, "kind": kind, "age": 0.0})

func grant_pickup(kind: String) -> void:
	var amount := party_pickup_amount()
	match kind:
		"health":
			player_health = mini(player_max_health, player_health + amount)
		"shield":
			player_shield = mini(player_max_shield, player_shield + amount)
		"weapon":
			player_weapon_level = mini(7, player_weapon_level + amount)
		"credits":
			score += roundi(45.0 * party_strength_multiplier())

func update_pickups(delta: float) -> void:
	for index in range(pickups.size() - 1, -1, -1):
		var pickup: Dictionary = pickups[index]
		var node: MeshInstance3D = pickup["node"]
		pickup["age"] = float(pickup["age"]) + delta
		node.position.x -= 4.0 * delta
		var difference: Vector3 = pilot.position - node.position
		if difference.length() < 7.0:
			node.position += difference.normalized() * minf(delta * 7.0, difference.length())
		if node.position.distance_to(pilot.position) < 1.0:
			grant_pickup(pickup["kind"])
			node.queue_free()
			pickups.remove_at(index)
		elif float(pickup["age"]) > 18.0 or node.position.x < -30.0:
			node.queue_free()
			pickups.remove_at(index)

func spawn_is_clear(center: Vector3, dimensions: Vector2) -> bool:
	var query := PhysicsShapeQueryParameters3D.new()
	var shape := CapsuleShape3D.new()
	shape.radius = dimensions.y * 0.36 + 0.1
	shape.height = maxf(dimensions.x * 0.84 + 0.2, shape.radius * 2)
	query.shape = shape
	query.transform = Transform3D(Basis(Vector3.BACK, PI / 2), center)
	query.collision_mask = 1 | 2 | 4
	return get_world_3d().direct_space_state.intersect_shape(query, 1).is_empty()

func set_sector(value: int) -> void:
	sector = posmod(value, BACKDROPS.size())
	if background_layers != null:
		background_layers.set_sector(sector)
	if space_world != null:
		space_world.set_sector(sector)

func _unhandled_key_input(event: InputEvent) -> void:
	if event is InputEventKey and event.pressed and not event.echo:
		if event.physical_keycode >= KEY_1 and event.physical_keycode <= KEY_5:
			select_weapon(event.physical_keycode - KEY_1)
		elif event.physical_keycode == KEY_TAB:
			set_sector(sector + 1)
		elif event.physical_keycode == KEY_T:
			tethered = not tethered
		elif event.physical_keycode == KEY_ESCAPE:
			show_flight_menu()

func _physics_process(delta: float) -> void:
	elapsed += delta
	player_invulnerability = maxf(0.0, player_invulnerability - delta)
	var axes := Vector2(float(Input.is_physical_key_pressed(KEY_D)) - float(Input.is_physical_key_pressed(KEY_A)), float(Input.is_physical_key_pressed(KEY_W)) - float(Input.is_physical_key_pressed(KEY_S)))
	var pads := Input.get_connected_joypads()
	var firing := Input.is_physical_key_pressed(KEY_SPACE) or Input.is_mouse_button_pressed(MOUSE_BUTTON_LEFT)
	if not pads.is_empty():
		var pad := pads[0]
		var stick := Vector2(Input.get_joy_axis(pad, JOY_AXIS_LEFT_X), -Input.get_joy_axis(pad, JOY_AXIS_LEFT_Y))
		if stick.length() > 0.16:
			axes = stick
		firing = firing or Input.get_joy_axis(pad, JOY_AXIS_TRIGGER_RIGHT) > 0.2 or Input.is_joy_button_pressed(pad, JOY_BUTTON_X)
	var desired := axes.limit_length() * 16
	if axes.length() < 0.1 and Input.is_mouse_button_pressed(MOUSE_BUTTON_LEFT):
		var mouse := get_viewport().get_mouse_position()
		var point = Plane(Vector3.BACK, 0).intersects_ray(camera.project_ray_origin(mouse), camera.project_ray_normal(mouse))
		if point != null:
			var difference: Vector3 = point - pilot.position
			desired = Vector2(difference.x, difference.y) * (7 if tethered else 3)
			desired = desired.limit_length(20)
	pilot.velocity = pilot.velocity.lerp(Vector3(desired.x, desired.y, 0), 1 - exp(-delta * 12))
	pilot.move_and_slide()
	fire_clock -= delta
	if firing and fire_clock <= 0 and shots.size() < SHOT_LIMIT:
		fire_volley()
	if not miniboss_spawned and elapsed >= 35.0:
		miniboss_spawned = spawn_boss(true) != null
	if not boss_spawned and elapsed >= 95.0:
		boss_spawned = spawn_boss(false) != null
	spawn_clock -= delta
	if spawn_clock <= 0 and enemies.size() < 24:
		var candidate := Vector3(27, sin(elapsed * 1.7) * 9, 0)
		if spawn_is_clear(candidate, Vector2(3.5, 1.6)):
			var enemy := make_body("scout", Vector2(3.5, 1.6), null, true)
			enemy.set_meta("health", scaled_enemy_health(2))
			enemy.set_meta("max_health", int(enemy.get_meta("health")))
			enemy.set_meta("fire_clock", randf_range(2.4, 4.0))
			enemy.position = candidate
			enemies.append(enemy)
			spawn_clock = 1.1
		else:
			spawn_clock = 0.2
	for enemy in enemies:
		if enemy.is_queued_for_deletion():
			continue
		var is_boss := bool(enemy.get_meta("boss", false))
		if is_boss:
			var phase_age := float(enemy.get_meta("phase_age", 0.0)) + delta
			var phase := boss_phase_at(phase_age)
			enemy.set_meta("phase_age", phase_age)
			if phase != enemy.get_meta("phase", "ATTACK"):
				enemy.set_meta("phase", phase)
				var hull := enemy.get_node("VisualSlot/HullSprite") as MeshInstance3D
				var hull_material := hull.material_override as StandardMaterial3D
				hull_material.emission = Color("63bfff") if phase == "SHIELD" else Color.WHITE
			enemy.velocity = navigation.direction(enemy, Vector3(17, clampf(sin(elapsed * 0.9) * 8, -9, 9), 0), Engine.get_physics_frames()) * 4
		else:
			enemy.velocity = navigation.direction(enemy, Vector3(-28, clampf(enemy.position.y, -10, 10), 0), Engine.get_physics_frames()) * 5
		enemy.move_and_slide()
		if enemy.position.x < -28 and not is_boss:
			navigation.forget(enemy)
			enemy.queue_free()
			continue
		var fire_clock: float = float(enemy.get_meta("fire_clock", 2.5)) - delta * party_attack_multiplier() * DIFFICULTY_FIRE_RATE[difficulty]
		enemy.set_meta("fire_clock", fire_clock)
		var phase := String(enemy.get_meta("phase", "ATTACK"))
		if fire_clock <= 0.0 and enemy.position.x < 23.0 and phase != "DAMAGE":
			spawn_enemy_projectile(enemy, is_boss)
			enemy.set_meta("fire_clock", (1.55 if phase == "SHIELD" else 0.95 if is_boss else 2.8) / DIFFICULTY_FIRE_RATE[difficulty])
	for i in range(shots.size() - 1, -1, -1):
		var shot: Dictionary = shots[i]
		var previous: Vector3 = shot.position
		shot.position += shot.velocity * delta
		var ray := PhysicsRayQueryParameters3D.create(previous, shot.position, 2 | 4 | 8, [pilot.get_rid()])
		var hit := get_world_3d().direct_space_state.intersect_ray(ray)
		if not hit.is_empty():
			if hit.collider is RigidBody3D and hit.collider.has_meta("health"):
				if space_world.damage_target(hit.collider, hit.position, int(shot["damage"]), shot.velocity):
					score += 25
			if hit.collider is CharacterBody3D and hit.collider in enemies and not hit.collider.is_queued_for_deletion():
				var target := hit.collider as CharacterBody3D
				var phase := String(target.get_meta("phase", "ATTACK"))
				var health: int = int(target.get_meta("health")) - boss_damage_amount(int(shot["damage"]), phase)
				var fraction := clampf(float(health) / float(target.get_meta("max_health", 1)), 0.0, 1.0)
				(target.get_node("VisualSlot") as NebulaVisualSlot).set_damage_fraction(fraction)
				if health <= 0:
					navigation.forget(target)
					target.queue_free()
					if bool(target.get_meta("boss", false)):
						score += 3000
						spawn_pickup(target.position, "health")
						spawn_pickup(target.position + Vector3(0, 1, 0), "shield")
					else:
						score += 100
						if randf() < 0.24:
							spawn_pickup(target.position, ["health", "shield", "weapon", "credits"].pick_random())
				else:
					target.set_meta("health", health)
			shots.remove_at(i)
		elif shot.position.x > 29:
			shots.remove_at(i)
	for i in range(enemy_shots.size() - 1, -1, -1):
		var shot: Dictionary = enemy_shots[i]
		var previous: Vector3 = shot.position
		shot.position += shot.velocity * delta
		var ray := PhysicsRayQueryParameters3D.create(previous, shot.position, 1, [pilot.get_rid()])
		var hit := get_world_3d().direct_space_state.intersect_ray(ray)
		if not hit.is_empty():
			damage_player()
			enemy_shots.remove_at(i)
		elif shot.position.x < -30 or shot.position.x > 30 or absf(shot.position.y) > 16:
			enemy_shots.remove_at(i)
	enemies = enemies.filter(func(enemy): return not enemy.is_queued_for_deletion())
	update_pickups(delta)
	for i in range(shots.size()):
		var shot: Dictionary = shots[i]
		projectile_mesh.multimesh.set_instance_transform(i, Transform3D(Basis.from_scale(shot["scale"]), shot["position"]))
	projectile_mesh.multimesh.visible_instance_count = shots.size()
	for i in range(enemy_shots.size()):
		var shot: Dictionary = enemy_shots[i]
		enemy_projectile_mesh.multimesh.set_instance_transform(i, Transform3D(Basis.from_scale(Vector3.ONE * 0.9), shot["position"]))
	enemy_projectile_mesh.multimesh.visible_instance_count = enemy_shots.size()
	for i in range(backdrops.size()):
		backdrops[i].position.y = sin(elapsed / 95) * 0.32
	var current_boss: CharacterBody3D
	for enemy in enemies:
		if bool(enemy.get_meta("boss", false)) and not enemy.is_queued_for_deletion():
			current_boss = enemy
			break
	var boss_status := ""
	if current_boss != null:
		boss_status = " | %s %s · %d/%d" % [current_boss.get_meta("boss_name"), current_boss.get_meta("phase"), current_boss.get_meta("health"), current_boss.get_meta("max_health")]
	status.text = "ENGINE PREVIEW | %s | %s | %s LV %d | P%d · HP %d/%d · SH %d/%d | SCORE %d%s\nWASD / left stick · LMB / RT fire · 1-5 weapon · T tether %s · Tab sector · Esc flight deck" % [BACKDROPS[sector].to_upper(), "RTX (no denoiser)" if rtx_active else "RASTER", WEAPONS[weapon_mode]["name"], player_weapon_level, party_size, player_health, player_max_health, player_shield, player_max_shield, score, boss_status, "ON" if tethered else "OFF"]
