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
@export var automatic_state_changes: bool = true
@export var debug_navigation_enabled: bool = true
@export var debug_interval: float = 0.5

@export_group("Flight behavior")
@export var patrol_radius: float = 14.0
@export var patrol_altitude: float = 14.0
@export var patrol_orbit_speed: float = 0.45
@export var stalk_radius: float = 7.0
@export var stalk_altitude: float = 8.0
@export var stalk_orbit_speed: float = 0.8
@export var attack_altitude: float = 3.5
@export var attack_distance: float = 5.0
@export var stalk_distance: float = 35.0

@onready var owl: CharacterBody3D = get_parent() as CharacterBody3D

var curr_phase: PHASE = PHASE.EARLY
var distance: Vector3 = Vector3.ZERO
var dist_val: float = 0.0
var phase_val: float = 0.0
var player: CharacterBody3D = null
var debug_timer: float = 0.0
var orbit_angle: float = 0.0
var patrol_center: Vector3 = Vector3.ZERO

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
	if owl != null:
		patrol_center = owl.global_position
		patrol_center.y = patrol_altitude
	var player_group := get_tree().get_nodes_in_group("player")
	for candidate in player_group:
		if candidate is CharacterBody3D and candidate != owl:
			player = candidate as CharacterBody3D
			break

func _process(delta: float) -> void:
	if owl == null:
		return

	update_phase()
	phase_val = PHASE_DICT[curr_phase]

	if player == null:
		return

	distance = owl.get_distance()
	dist_val = get_dist_value(distance.length())

func update_behavior(player_visible: bool) -> void:
	if not automatic_state_changes:
		return
	if player == null or not player_visible:
		curr_state = STATES.PATROL
		return

	var horizontal_distance := Vector2(distance.x, distance.z).length()
	if horizontal_distance <= attack_distance:
		curr_state = STATES.ATTACK
	elif horizontal_distance <= stalk_distance:
		curr_state = STATES.STALK
	else:
		curr_state = STATES.PATROL
	

func set_player(target: CharacterBody3D) -> void:
	if target == player:
		if not target_position.is_equal_approx(target.global_position):
			target_position = target.global_position
		return
	player = target
	if player != null:
		target_position = player.global_position

func get_flight_direction(delta: float) -> Vector3:
	if owl == null:
		return Vector3.ZERO

	var center := patrol_center
	var radius := patrol_radius
	var orbit_speed := patrol_orbit_speed
	var altitude := patrol_altitude
	if curr_state == STATES.STALK and player != null:
		center = player.global_position
		center.y += stalk_altitude
		radius = stalk_radius
		orbit_speed = stalk_orbit_speed
	elif curr_state == STATES.ATTACK and player != null:
		# Stay airborne during attack; the attack closes in above the player.
		var attack_target := player.global_position + Vector3.UP * attack_altitude
		return owl.global_position.direction_to(attack_target)

	orbit_angle = fmod(orbit_angle + orbit_speed * delta, TAU)
	var orbit_target := center + Vector3(cos(orbit_angle) * radius, 0.0, sin(orbit_angle) * radius)
	if curr_state == STATES.PATROL:
		orbit_target.y = altitude
	return owl.global_position.direction_to(orbit_target)

func get_follow_direction() -> Vector3:
	if player == null or is_navigation_finished():
		return Vector3.ZERO

	var next_path_position: Vector3 = get_next_path_position()
	var direction: Vector3 = next_path_position - owl.global_position
	direction.y = 0.0
	if direction.length_squared() > 0.0:
		return direction.normalized()
	return Vector3.ZERO
