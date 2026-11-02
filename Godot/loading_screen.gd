extends Node

const GAME_SCENE := "res://Godot/arena.tscn"
const GAME_RESOURCES := [
	"res://Web/public/assets/ship.webp",
	"res://Web/public/assets/scout.webp",
	"res://Web/public/assets/rock.webp",
	"res://Web/public/assets/rock2.webp",
	"res://Web/public/assets/spaceFrontier.webp",
	"res://Web/public/assets/spaceRift.webp",
	"res://Web/public/assets/spaceInferno.webp",
	"res://Godot/space_gi.res",
]

@export var auto_start := true
var status_label: Label
var progress_bar: ProgressBar
var overlay: CanvasLayer

func _ready() -> void:
	_build_loading_ui()
	if auto_start:
		_load_game.call_deferred()

func _build_loading_ui() -> void:
	overlay = CanvasLayer.new()
	overlay.name = "LoadingUi"
	overlay.layer = 10
	add_child(overlay)

	var ui := Control.new()
	ui.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	ui.theme = _make_theme()
	overlay.add_child(ui)

	var background := ColorRect.new()
	background.color = Color("030914")
	background.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	ui.add_child(background)

	var center := CenterContainer.new()
	center.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	ui.add_child(center)

	var panel := PanelContainer.new()
	panel.custom_minimum_size = Vector2(720, 340)
	center.add_child(panel)

	var content := VBoxContainer.new()
	content.alignment = BoxContainer.ALIGNMENT_CENTER
	content.add_theme_constant_override("separation", 20)
	panel.add_child(content)

	var title := Label.new()
	title.text = "IRON NEBULA"
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title.add_theme_color_override("font_color", Color("e9f8ff"))
	title.add_theme_font_size_override("font_size", 42)
	content.add_child(title)

	var subtitle := Label.new()
	subtitle.text = "NVIDIA ENGINE PREVIEW"
	subtitle.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	subtitle.add_theme_color_override("font_color", Color("53ddff"))
	subtitle.add_theme_font_size_override("font_size", 16)
	content.add_child(subtitle)

	status_label = Label.new()
	status_label.text = "PREPARING FLIGHT SYSTEMS..."
	status_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	status_label.add_theme_color_override("font_color", Color("b8d7e5"))
	status_label.add_theme_font_size_override("font_size", 16)
	content.add_child(status_label)

	progress_bar = ProgressBar.new()
	progress_bar.custom_minimum_size = Vector2(520, 20)
	progress_bar.max_value = 100
	progress_bar.show_percentage = false
	content.add_child(progress_bar)

func _make_theme() -> Theme:
	var theme := Theme.new()
	var panel := StyleBoxFlat.new()
	panel.bg_color = Color("071421")
	panel.border_color = Color("2aabc9")
	panel.set_border_width_all(2)
	panel.set_corner_radius_all(8)
	panel.content_margin_left = 48
	panel.content_margin_right = 48
	panel.content_margin_top = 34
	panel.content_margin_bottom = 34
	panel.shadow_color = Color(0.0, 0.55, 0.85, 0.22)
	panel.shadow_size = 24
	theme.set_stylebox("panel", "PanelContainer", panel)

	var track := StyleBoxFlat.new()
	track.bg_color = Color("142737")
	track.set_corner_radius_all(6)
	var fill := StyleBoxFlat.new()
	fill.bg_color = Color("48d8f3")
	fill.set_corner_radius_all(6)
	theme.set_stylebox("background", "ProgressBar", track)
	theme.set_stylebox("fill", "ProgressBar", fill)
	return theme

func _load_game() -> void:
	await get_tree().process_frame
	await get_tree().process_frame

	var paths: Array[String] = [GAME_SCENE]
	paths.append_array(GAME_RESOURCES)
	for path in paths:
		var error := ResourceLoader.load_threaded_request(path, "", true)
		if error != OK:
			_show_failure("Could not request %s: %s" % [path, error_string(error)])
			return

	var completed := 0
	while completed < paths.size():
		completed = 0
		for path in paths:
			var progress: Array[float] = []
			match ResourceLoader.load_threaded_get_status(path, progress):
				ResourceLoader.THREAD_LOAD_LOADED:
					completed += 1
				ResourceLoader.THREAD_LOAD_FAILED:
					_show_failure("Could not load %s." % path)
					return
				ResourceLoader.THREAD_LOAD_IN_PROGRESS:
					pass
				_:
					_show_failure("Resource loading stopped unexpectedly: %s." % path)
					return
		progress_bar.value = 100.0 * completed / paths.size()
		status_label.text = "LOADING GAME RESOURCES  %d%%" % int(progress_bar.value)
		await get_tree().process_frame

	var packed_scene := ResourceLoader.load_threaded_get(GAME_SCENE) as PackedScene
	if packed_scene == null:
		_show_failure("The game scene did not load.")
		return

	status_label.text = "PREPARING GRAPHICS PIPELINES..."
	progress_bar.value = 100
	var game := packed_scene.instantiate()
	get_tree().root.add_child(game)
	for frame in range(3):
		await get_tree().process_frame

	get_tree().current_scene = game
	print("Iron Nebula preview ready: resources loaded and graphics pipeline warm-up complete.")
	overlay.queue_free()
	queue_free()

func _show_failure(message: String) -> void:
	status_label.text = "STARTUP FAILED — SEE THE GODOT OUTPUT LOG"
	progress_bar.value = 0
	push_error(message)
