extends CharacterBody3D

const GRAVITY: float = -24.8
const MAX_SPEED: float = 8.0
const JUMP_SPEED: float = 10.0
const ACCEL: float = 10.0
const TURN_ACCEL: float = 60.0
const DECEL: float = 100.0
const SPEED_MULTIPLIER: float = 1.6

@export var mouse_sensitivity: float = 0.2

var near_den: bool = false

@onready var rotation_helper: Node3D = $Rotation_Helper
@onready var spawn_point: Node3D = $/root/main/Floor/SpawnPoint
@onready var needs: Node = $Needs

func _ready() -> void:
	Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)
	
	if spawn_point:
		_teleport_to_spawn.call_deferred()

func _teleport_to_spawn() -> void:
	global_position = spawn_point.global_position
	velocity = Vector3.ZERO # Reset any leftover velocity

func _physics_process(delta: float) -> void:
	process_input()
	apply_gravity(delta)
	process_movement(delta)
	move_and_slide()

func process_input() -> void:
	# Capturing/Freeing the cursor
	if Input.is_action_just_pressed("point"):
		if Input.get_mouse_mode() == Input.MOUSE_MODE_VISIBLE:
			Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)
		else:
			Input.set_mouse_mode(Input.MOUSE_MODE_VISIBLE)

func process_movement(delta: float) -> void:
	var input: Vector2 = Input.get_vector(
		"move_left",
		"move_right",
		"move_backward",
		"move_forward"
	)
	var dir: Vector3 = global_basis * Vector3(input.x, 0, -input.y)
	
	var current_speed: float = MAX_SPEED
	if Input.is_action_pressed("sprint"):
		current_speed *= SPEED_MULTIPLIER
	var hvel: Vector3 = velocity
	hvel.y = 0
	var target: Vector3 = dir * current_speed
	
	var acceleration: float = DECEL
	if dir != Vector3.ZERO:
		# Turn quickly when the current momentum points against the new input.
		acceleration = TURN_ACCEL if hvel.dot(dir) < 0.0 else ACCEL
	hvel = hvel.move_toward(target, acceleration * delta)
	velocity.x = hvel.x
	velocity.z = hvel.z

func apply_gravity(delta: float) -> void:
	if is_on_floor():
		if Input.is_action_just_pressed("jump"):
			velocity.y = JUMP_SPEED
		else:
			velocity.y = -0.5
	else:
		velocity.y += GRAVITY * delta

func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventMouseMotion and Input.get_mouse_mode() == Input.MOUSE_MODE_CAPTURED:
		rotation_helper.rotate_x(deg_to_rad(-event.relative.y * mouse_sensitivity))
		rotate_y(deg_to_rad(-event.relative.x * mouse_sensitivity))
		rotation_helper.rotation.x = clampf(rotation_helper.rotation.x, deg_to_rad(-70), deg_to_rad(70))
