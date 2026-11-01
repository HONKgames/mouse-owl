extends CharacterBody3D

@export var fov_degree: float = 60.0
@export var detection_area: float = 25.0

@onready var vision_area: Area3D = $VisionArea
@onready var raycast: RayCast3D = $RayCast3D
@onready var nav_agent: NavigationAgent3D = $NavigationAgent3D

var is_player_visible: bool = false
var player: CharacterBody3D = null
var speed: float = 20.0
var gravity: float = 9.81

#enum STATES = {PATROL, STALK, ATTACK}

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	pass # Replace with function body.
	
func _physics_process(delta: float) -> void:
	if not is_on_floor():
		velocity.y -= gravity * delta
	
	#var curr_state = nav_agent.calculate_state()
	#var direction := nav_agent.next_position(curr_state)
	#velocity.x = direction.x * speed
	#velocity.y += direction.y * speed
	
	move_and_slide()
	
func detection() -> void:
	is_player_visible = false
	if not player: return
	
	var distance = get_distance()
	if distance.length() > detection_area: return
	if not inLOS(distance): return 
	
	raycast.global_transform.origin = distance
	raycast.target_position = raycast.to_local(player.global_transform.origin) #player position
	raycast.force_raycast_update()

	if raycast.is_colliding() and raycast.get_collider() == player:
		is_player_visible = true
		
func get_distance() -> Vector3:
	var pos: Vector3 = global_transform.origin
	var target_pos: Vector3 = player.global_transform.origin
	return (target_pos - pos)

func inLOS(distance) -> bool:
	var forward: Vector3 = -global_transform.basis.z 
	var dir: Vector3 = distance.normalized()
	var dot_val: float = forward.dot(dir)
	var angle_threshold: float = cos(deg_to_rad(fov_degree))
	if dot_val >= angle_threshold: return true
	return false

func _on_vision_area_body_entered(body: Node3D) -> void:
	if body.is_in_group("player"):
		player = body

func _on_vision_area_body_exited(body: Node3D) -> void:
	if body.is_in_group("player"):
		player = null
		is_player_visible = false
