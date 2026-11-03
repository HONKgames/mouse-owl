extends CharacterBody3D

@export var fov_degree: float = 60.0
@export var detection_area: float = 25.0
@export var speed: float = 4.0
@export var flight_acceleration: float = 6.0
@export var turn_speed: float = 8.0
@export var movement_animation: StringName = &"ArmatureAction"
@export var movement_threshold: float = 0.05
@export var debug_enabled: bool = true
@export var player_path: NodePath

@onready var vision_area: Area3D = $Area3D
@onready var raycast: RayCast3D = $RayCast3D
@onready var nav_agent: OwlNavigationAgent = $NavigationAgent3D
@onready var animation_player: AnimationPlayer = find_child("AnimationPlayer", true, false) as AnimationPlayer

var is_player_visible: bool = false
var player: CharacterBody3D = null
var debug_timer: float = 0.0

func _ready() -> void:
	_find_player()

func _physics_process(delta: float) -> void:
	if player == null:
		_find_player()

	if player != null:
		nav_agent.set_player(player)
		detection()
	nav_agent.update_behavior(is_player_visible)

	var direction := nav_agent.get_flight_direction(delta)
	var desired_velocity := direction * speed
	velocity = velocity.move_toward(desired_velocity, flight_acceleration * delta)
	_face_player_or_direction(direction, delta)
		
	if debug_enabled and debug_timer <= 0.0:
		print("Owl state=", nav_agent.get_state(), " phase=", nav_agent.get_phase(), " velocity=", velocity)
		debug_timer = 0.5
	else:
		debug_timer -= delta
	move_and_slide()
	_update_movement_animation()

func _update_movement_animation() -> void:
	if animation_player == null or not animation_player.has_animation(movement_animation):
		return

	var is_moving := velocity.length_squared() > movement_threshold * movement_threshold
	if is_moving:
		if animation_player.current_animation != movement_animation or not animation_player.is_playing():
			animation_player.play(movement_animation)
	elif animation_player.current_animation == movement_animation:
		animation_player.stop()

func _face_player_or_direction(direction: Vector3, delta: float) -> void:
	var facing := direction
	if facing.length_squared() <= 0.001:
		return

	facing = facing.normalized()
	var target_yaw := atan2(-facing.x, -facing.z)
	rotation.y = lerp_angle(rotation.y, target_yaw, minf(turn_speed * delta, 1.0))

func _find_player() -> void:
	if not player_path.is_empty():
		player = get_node_or_null(player_path) as CharacterBody3D

	if player == null:
		var player_group := get_tree().get_nodes_in_group("player")
		for candidate in player_group:
			if candidate is CharacterBody3D and candidate != self:
				player = candidate as CharacterBody3D
				break

func detection() -> void:
	is_player_visible = false
	if player == null:
		return

	var distance := get_distance()
	if distance.length() > detection_area:
		return
	if not inLOS(distance):
		return

	raycast.global_position = global_position
	raycast.target_position = raycast.to_local(player.global_position)
	raycast.force_raycast_update()

	if raycast.is_colliding() and raycast.get_collider() == player:
		is_player_visible = true

func get_distance() -> Vector3:
	if player == null:
		return Vector3.ZERO
	return player.global_position - global_position

func inLOS(distance: Vector3) -> bool:
	var forward := -global_transform.basis.z
	var direction := distance.normalized()
	var dot_val := forward.dot(direction)
	var angle_threshold := cos(deg_to_rad(fov_degree))
	return dot_val >= angle_threshold

func _on_vision_area_body_entered(body: Node3D) -> void:
	if body.is_in_group("player"):
		player = body as CharacterBody3D

func _on_vision_area_body_exited(body: Node3D) -> void:
	if body == player:
		player = null
		is_player_visible = false
