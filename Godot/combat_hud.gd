extends CanvasLayer

const CYAN := Color("58dcf4")
const AMBER := Color("ffc66d")
const MUTED := Color("93a9b5")

var sector_label: Label
var mission_label: Label
var score_label: Label
var combo_label: Label
var accuracy_label: Label
var health_label: Label
var shield_label: Label
var reserve_label: Label
var weapon_label: Label
var wave_label: Label
var health_bar: ProgressBar
var shield_bar: ProgressBar
var weapon_bar: ProgressBar
var boss_panel: PanelContainer
var boss_label: Label
var boss_bar: ProgressBar
var boss_value: Label
var event_label: Label
var telemetry_label: Label
var boss_tint := Color("ff765f")
var event_time := 0.0
var telemetry_clock := 0.0

func _ready() -> void:
	layer = 8
	var root := Control.new()
	root.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	root.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(root)

	var top := _panel(root, 0.0, 0.0, 1.0, 0.0, 20, 16, -20, 136, CYAN)
	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 20)
	top.add_child(row)

	var mission := _stack(row, 226)
	_add_caption(mission, "IRON NEBULA   /   PRO-ARCADE")
	sector_label = _add_value(mission, "FRONTIER", 21)
	mission_label = _add_caption(mission, "STANDARD   ·   SYSTEMS NOMINAL")

	var score_stack := _stack(row, 0)
	score_stack.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_add_caption(score_stack, "FLIGHT SCORE     /     LIVE RUN")
	score_label = _add_value(score_stack, "0000000", 27)
	var score_row := HBoxContainer.new()
	score_row.add_theme_constant_override("separation", 22)
	score_stack.add_child(score_row)
	combo_label = _add_caption(score_row, "CHAIN  0   ×1")
	combo_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	accuracy_label = _add_caption(score_row, "ACCURACY  100%")

	var system_stack := _stack(row, 318)
	_add_caption(system_stack, "FLIGHT SYSTEMS")
	health_label = _add_caption(system_stack, "HULL  4 / 4")
	health_bar = _bar(system_stack, Color("ff6c65"))
	shield_label = _add_caption(system_stack, "SHIELD  2 / 3")
	shield_bar = _bar(system_stack, CYAN)
	reserve_label = _add_caption(system_stack, "LIVES  03     ·     CR 00000")

	var lower := _panel(root, 0.0, 1.0, 1.0, 1.0, 20, -84, -20, -16, Color("334e63"))
	var lower_row := HBoxContainer.new()
	lower_row.add_theme_constant_override("separation", 20)
	lower.add_child(lower_row)
	var lower_left := _stack(lower_row, 0)
	lower_left.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	weapon_label = _add_caption(lower_left, "01  PULSE     /     LV 1")
	weapon_bar = _bar(lower_left, Color("54d9f3"))
	var lower_right := _stack(lower_row, 420)
	wave_label = _add_caption(lower_right, "WAVE 01  ·  00:00")
	telemetry_label = _add_caption(lower_right, "PRO-ARCADE  ·  60 FPS")

	boss_panel = _panel(root, 0.24, 0.0, 0.76, 0.0, 0, 124, 0, 186, Color("ff765f"))
	var boss_stack := _stack(boss_panel, 0)
	var boss_row := HBoxContainer.new()
	boss_row.add_theme_constant_override("separation", 12)
	boss_stack.add_child(boss_row)
	boss_label = _add_caption(boss_row, "HOSTILE SIGNATURE")
	boss_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	boss_value = _add_caption(boss_row, "000 / 000")
	boss_bar = _bar(boss_stack, boss_tint)
	boss_panel.visible = false

	event_label = Label.new()
	event_label.set_anchors_preset(Control.PRESET_CENTER_BOTTOM)
	event_label.position = Vector2(-330, -122)
	event_label.size = Vector2(660, 38)
	event_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	event_label.add_theme_font_size_override("font_size", 18)
	event_label.add_theme_color_override("font_color", CYAN)
	event_label.add_theme_color_override("font_shadow_color", Color(0.0, 0.05, 0.09, 0.95))
	event_label.add_theme_constant_override("shadow_offset_x", 2)
	event_label.add_theme_constant_override("shadow_offset_y", 2)
	event_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	root.add_child(event_label)

func _panel(parent: Control, left: float, top: float, right: float, bottom: float, x1: float, y1: float, x2: float, y2: float, accent: Color) -> PanelContainer:
	var panel := PanelContainer.new()
	panel.anchor_left = left
	panel.anchor_top = top
	panel.anchor_right = right
	panel.anchor_bottom = bottom
	panel.offset_left = x1
	panel.offset_top = y1
	panel.offset_right = x2
	panel.offset_bottom = y2
	var style := StyleBoxFlat.new()
	style.bg_color = Color("06111c", 0.9)
	style.border_color = Color(accent, 0.58)
	style.set_border_width_all(1)
	style.border_width_left = 3
	style.set_corner_radius_all(3)
	style.content_margin_left = 14
	style.content_margin_right = 14
	style.content_margin_top = 9
	style.content_margin_bottom = 8
	panel.add_theme_stylebox_override("panel", style)
	panel.mouse_filter = Control.MOUSE_FILTER_IGNORE
	parent.add_child(panel)
	return panel

func _stack(parent: Control, minimum_width: float) -> VBoxContainer:
	var stack := VBoxContainer.new()
	stack.custom_minimum_size.x = minimum_width
	stack.size_flags_vertical = Control.SIZE_EXPAND_FILL
	stack.add_theme_constant_override("separation", 3)
	parent.add_child(stack)
	return stack

func _add_caption(parent: Control, text: String) -> Label:
	var label := Label.new()
	label.text = text
	label.add_theme_font_size_override("font_size", 14)
	label.add_theme_color_override("font_color", MUTED)
	label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	parent.add_child(label)
	return label

func _add_value(parent: Control, text: String, size: int) -> Label:
	var label := Label.new()
	label.text = text
	label.add_theme_font_size_override("font_size", size)
	label.add_theme_color_override("font_color", Color("edf7fa"))
	label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	parent.add_child(label)
	return label

func _bar(parent: Control, color: Color) -> ProgressBar:
	var bar := ProgressBar.new()
	bar.custom_minimum_size.y = 7
	bar.min_value = 0.0
	bar.max_value = 1.0
	bar.show_percentage = false
	bar.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var track := StyleBoxFlat.new()
	track.bg_color = Color("172b39")
	var fill := StyleBoxFlat.new()
	fill.bg_color = color
	fill.set_corner_radius_all(2)
	bar.add_theme_stylebox_override("background", track)
	bar.add_theme_stylebox_override("fill", fill)
	parent.add_child(bar)
	return bar

func show_event(message: String, tint: Color = CYAN) -> void:
	event_label.text = message
	event_label.add_theme_color_override("font_color", tint)
	event_label.modulate.a = 1.0
	event_time = 2.2

func set_state(state: Dictionary, delta: float) -> void:
	telemetry_clock -= delta
	if telemetry_clock <= 0.0:
		telemetry_clock = 0.25
		telemetry_label.text = "PRO-ARCADE  ·  %d FPS" % Engine.get_frames_per_second()

	var health: int = int(state.get("health", 0))
	var max_health: int = maxi(1, int(state.get("max_health", 1)))
	var shield: int = int(state.get("shield", 0))
	var max_shield: int = maxi(1, int(state.get("max_shield", 1)))
	var lives: int = int(state.get("lives", 3))
	var credits: int = int(state.get("credits", 0))
	var weapon_level: int = int(state.get("weapon_level", 1))
	var combo: int = int(state.get("combo", 0))
	sector_label.text = "%s   /   SECTOR %02d" % [String(state.get("sector_name", "FRONTIER")), int(state.get("sector", 0)) + 1]
	mission_label.text = "%s   ·   %s" % [String(state.get("difficulty", "STANDARD")), String(state.get("run_status", "SYSTEMS NOMINAL"))]
	score_label.text = "%07d" % int(state.get("score", 0))
	combo_label.text = "CHAIN  %02d   ×%d" % [combo, int(state.get("multiplier", 1))]
	combo_label.add_theme_color_override("font_color", AMBER if combo >= 4 else MUTED)
	accuracy_label.text = "ACCURACY  %d%%" % int(state.get("accuracy", 100))
	health_label.text = "HULL  %d / %d" % [health, max_health]
	health_label.add_theme_color_override("font_color", Color("ff796d") if health <= 1 else MUTED)
	health_bar.value = float(health) / max_health
	shield_label.text = "SHIELD  %d / %d" % [shield, max_shield]
	shield_bar.value = float(shield) / max_shield
	reserve_label.text = "LIVES  %02d     ·     CR %05d" % [lives, credits]
	var weapon_index: int = int(state.get("weapon_index", 0)) + 1
	weapon_label.text = "%02d  %s     /     LV %d" % [weapon_index, String(state.get("weapon", "PULSE")), weapon_level]
	weapon_bar.value = float(weapon_level) / 7.0
	wave_label.text = "WAVE %02d  ·  %s" % [int(state.get("wave", 1)), String(state.get("elapsed", "00:00"))]

	var boss_health: int = int(state.get("boss_health", 0))
	var boss_max: int = maxi(1, int(state.get("boss_max_health", 1)))
	boss_panel.visible = boss_health > 0
	if boss_health > 0:
		var phase := String(state.get("boss_phase", "ATTACK"))
		boss_tint = Color("69ddff") if phase == "SHIELD" else Color("ffc66d") if phase == "DAMAGE" else Color("ff765f")
		boss_label.text = "%s   /   %s PHASE" % [String(state.get("boss_name", "HOSTILE")), phase]
		boss_label.add_theme_color_override("font_color", boss_tint)
		boss_value.text = "%03d / %03d" % [boss_health, boss_max]
		boss_bar.value = float(boss_health) / boss_max
		var fill := StyleBoxFlat.new()
		fill.bg_color = boss_tint
		fill.set_corner_radius_all(2)
		boss_bar.add_theme_stylebox_override("fill", fill)

	event_time = maxf(0.0, event_time - delta)
	event_label.visible = event_time > 0.0
	event_label.modulate.a = minf(1.0, event_time * 2.0)
