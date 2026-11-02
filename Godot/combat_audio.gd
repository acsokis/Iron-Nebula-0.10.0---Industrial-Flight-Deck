extends Node

const MUSIC_PATH := "res://Assets/Audio/Propulsive Peak.mp3"
const SOUND_PATHS := {
	"pulse": "res://Assets/Audio/pulse.wav",
	"lance": "res://Assets/Audio/lance.wav",
	"arc": "res://Assets/Audio/arc.wav",
	"gatling": "res://Assets/Audio/gatling.wav",
	"beam": "res://Assets/Audio/beam.wav",
	"impact": "res://Assets/Audio/hit.wav",
	"explosion": "res://Assets/Audio/explosion.wav",
	"shield": "res://Assets/Audio/shield.wav",
	"pickup": "res://Assets/Audio/pickup.wav",
	"boss": "res://Assets/Audio/boss_warning.wav",
	"phase": "res://Assets/Audio/boss_phase.wav",
	"damage": "res://Assets/Audio/damage.wav",
}
const VOICE_COUNT := 12

var music_player: AudioStreamPlayer
var voices: Array[AudioStreamPlayer3D] = []
var streams: Dictionary = {}
var next_voice := 0

func _ready() -> void:
	music_player = AudioStreamPlayer.new()
	music_player.name = "Soundtrack"
	music_player.volume_db = -12.0
	var soundtrack := load(MUSIC_PATH) as AudioStream
	if soundtrack == null:
		push_error("Godot soundtrack failed to load: %s" % MUSIC_PATH)
	else:
		if soundtrack is AudioStreamMP3:
			(soundtrack as AudioStreamMP3).loop = true
		music_player.stream = soundtrack
	add_child(music_player)

	for key in SOUND_PATHS:
		var path: String = SOUND_PATHS[key]
		var stream := load(path) as AudioStream
		if stream == null:
			push_error("Godot sound effect failed to load: %s" % path)
		else:
			streams[key] = stream
	for index in range(VOICE_COUNT):
		var voice := AudioStreamPlayer3D.new()
		voice.name = "SfxVoice%02d" % index
		voice.max_distance = 88.0
		voice.unit_size = 12.0
		voice.volume_db = -5.0
		voice.attenuation_model = AudioStreamPlayer3D.ATTENUATION_INVERSE_DISTANCE
		add_child(voice)
		voices.append(voice)

func start_music() -> void:
	if music_player.stream != null and not music_player.playing:
		music_player.play()

func _exit_tree() -> void:
	stop_all()

func stop_all() -> void:
	if is_instance_valid(music_player):
		music_player.stop()
		music_player.stream = null
	for voice in voices:
		voice.stop()
		voice.stream = null
	streams.clear()

func play_effect(effect: String, world_position: Vector3 = Vector3.ZERO) -> void:
	var stream := streams.get(effect) as AudioStream
	if stream == null or voices.is_empty():
		return
	var voice := voices[next_voice]
	next_voice = (next_voice + 1) % voices.size()
	voice.stop()
	voice.stream = stream
	voice.global_position = world_position
	voice.play()
