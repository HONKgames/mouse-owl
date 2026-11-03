extends Node

@onready var music_player: AudioStreamPlayer3D = $MusicPlayer
@onready var ambience_player: AudioStreamPlayer3D = $AmbiencePlayer
@onready var player: CharacterBody3D = get_tree().get_first_node_in_group("player") as CharacterBody3D

const DAY_START = 0.25
const DAY_END = 0.75
const FADE_SPEED = 40.0

var den_amb_list: Array[String] = [
    "res://assets/sounds/sfx/den_amb1.mp3"
]

var day_amb_list: Array[String] = [
	"res://assets/sounds/sfx/day_amb1.wav",
    "res://assets/sounds/sfx/day_amb2.wav"
]

var night_amb_list: Array[String] = [
	"res://assets/sounds/sfx/night_amb1.wav",
	"res://assets/sounds/sfx/night_amb2.mp3",
	"res://assets/sounds/sfx/night_amb3.wav",
	"res://assets/sounds/sfx/night_amb4.wav",
	"res://assets/sounds/sfx/night_amb5.mp3"
]

var amb_timer: Timer

func _ready() -> void:
	amb_timer = Timer.new()
	amb_timer.wait_time = randf_range(8.0, 15.0)
	amb_timer.one_shot = false
	amb_timer.autostart = true
	amb_timer.timeout.connect(_play_random_ambience)
	add_child(amb_timer)

func _process(delta: float) -> void:
	var current_time: float = TimeGlobal.get_time()
	var is_day: bool = current_time >= DAY_START and current_time < DAY_END
	
	var target_volume: float = 0.0 if is_day else -80.0
	
	if is_day and not music_player.playing:
		music_player.volume_db = -80.0
		music_player.play()
	
	music_player.volume_db = move_toward(music_player.volume_db, target_volume, FADE_SPEED * delta)
	
	if not is_day and music_player.playing and music_player.volume_db <= -79.0:
		music_player.stop()

func _play_random_ambience() -> void:
	if ambience_player.playing:
		return

	var current_time: float = TimeGlobal.get_time()
	var is_day: bool = current_time >= DAY_START and current_time < DAY_END
	
	var current_pool: Array
	if player and player.has_node("DenUI") and player.get_node("DenUI").visible:
		current_pool = den_amb_list
	elif is_day:
		current_pool = day_amb_list
	else:
		current_pool = night_amb_list

	if current_pool.size() > 0:
		var random_file: String = current_pool[randi() % current_pool.size()]
		ambience_player.stream = load(random_file)
		ambience_player.play()

	amb_timer.wait_time = randf_range(10.0, 20.0)
