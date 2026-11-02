extends CharacterBody3D

@export var fov_degree: float = 60.0
@export var detection_area: float = 25.0
@export var speed: float = 4.0
@export var debug_enabled: bool = true
@export var player_path: NodePath

@onready var vision_area: Area3D = $Area3D
@onready var raycast: RayCast3D = $RayCast3D
@onready var nav_agent: OwlNavigationAgent = $NavigationAgent3D

var is_player_visible: bool = false
var player: CharacterBody3D = null
var gravity: float = 9.81
var debug_timer: float = 0.0

func _ready() -> void:
	_find_player()

func _physics_process(delta: float) -> void:
	if player == null:
		_find_player()

	if player != null:
		nav_agent.set_player(player)
		detection()
		var direction := nav_agent.get_follow_direction()
		velocity.x = direction.x * speed
		velocity.z = direction.z * speed
	else:
		velocity.x = 0.0
		velocity.z = 0.0

	if not is_on_floor():
		velocity.y -= gravity * delta
	else:
		velocity.y = 0.0
		
	if debug_enabled and debug_timer <= 0.0:
		print("Owl state=", nav_agent.get_state(), " phase=", nav_agent.get_phase(), " velocity=", velocity)
		debug_timer = 0.5
	else:
		debug_timer -= delta
	move_and_slide()

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
