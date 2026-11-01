extends Node3D

@export var fov_degree: float = 60.0
@export var detection_area: float = 25.0

@onready var vision_area: Area3D = $VisionArea
@onready var raycast: RayCast3D = $RayCast3D

var is_player_visible: bool = false
var player: CharacterBody3D = null

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	pass # Replace with function body.
	
func get_distance() -> float:
	var pos: Vector3 = global_transform.origin
	var target_pos: Vector3 = player.global_transform.origin
	return (target_pos - pos).length()
	
func _physics_process(_delta: float) -> void:
	detection()
	
func detection() -> void:
	is_player_visible = false
	if not player:
		return

	var distance = get_distance()
	if distance.length() > detection_area:
		return
		
	var forward: Vector3 = -global_transform.basis.z 
	var dir_to_target: Vector3 = distance.normalized()
	var dot_val: float = forward.dot(dir_to_target)
	var angle_threshold: float = cos(deg_to_rad(fov_degree))

	if dot_val < angle_threshold:
		return 

	raycast.global_transform.origin = distance
	raycast.target_position = raycast.to_local(player.global_transform.origin) #player position
	raycast.force_raycast_update()

	if raycast.is_colliding() and raycast.get_collider() == player:
		is_player_visible = true

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _on_vision_area_body_entered(body: Node3D) -> void:
	if body.is_in_group("player"):
		player = body

func _on_vision_area_body_exited(body: Node3D) -> void:
	if body.is_in_group("player"):
		player = null
		is_player_visible = false
