extends NavigationAgent3D
class_name OwlNavigationAgent

enum STATES { PATROL, STALK, ATTACK }
enum PHASE { EARLY, MIDDLE, LATE }

const PHASE_DICT := {
	PHASE.EARLY: 0.3,
	PHASE.MIDDLE: 0.5,
	PHASE.LATE: 0.8
}

@export var curr_state: STATES = STATES.PATROL
@export var debug_navigation_enabled: bool = true
@export var debug_interval: float = 0.5

@onready var owl: CharacterBody3D = get_parent() as CharacterBody3D

var curr_phase: PHASE = PHASE.EARLY
var distance: Vector3 = Vector3.ZERO
var dist_val: float = 0.0
var phase_val: float = 0.0
var player: CharacterBody3D = null
var debug_timer: float = 0.0

func get_state() -> STATES:
	return curr_state

func get_dist_value(distance_value: float) -> float:
	if distance_value <= 30.0:
		return 0.7
	elif distance_value <= 60.0:
		return 0.4
	elif distance_value < 100.0:
		return 0.2
	return 0.0

func get_phase() -> PHASE:
	return curr_phase

func update_phase() -> void:
	var time_global := get_node_or_null("/root/TimeGlobal")
	if time_global != null and time_global.has_method("get_night_phase"):
		var next_phase = time_global.get_night_phase()
		if PHASE_DICT.has(next_phase):
			curr_phase = next_phase

func _ready() -> void:
	var player_group := get_tree().get_nodes_in_group("player")
	if player_group.size() > 0:
		player = player_group[0] as CharacterBody3D

func _process(delta: float) -> void:
	if owl == null:
		return

	update_phase()
	phase_val = PHASE_DICT[curr_phase]

	if player == null:
		return

	distance = owl.get_distance()
	dist_val = get_dist_value(distance.length())
	target_position = player.global_position
	

func set_player(target: CharacterBody3D) -> void:
	player = target
	if player != null:
		curr_state = STATES.STALK
		# CODEX: Set the target immediately before Owl.gd asks for a direction.
		target_position = player.global_position

func get_follow_direction() -> Vector3:
	if player == null or is_navigation_finished():
		return Vector3.ZERO

	var next_path_position: Vector3 = get_next_path_position()
	var direction: Vector3 = next_path_position - owl.global_position
	direction.y = 0.0
	if direction.length_squared() > 0.0:
		return direction.normalized()
	return Vector3.ZERO
