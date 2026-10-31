extends CharacterBody3D

const GRAVITY = -24.8
const MAX_SPEED = 8.0
const JUMP_SPEED = 10.0
const ACCEL = 10.0
const TURN_ACCEL = 60.0
const DEACCEL = 100.0
const MAX_SLOPE_ANGLE = 40.0
const SPEED_MULTIPLIER = 1.6

var MOUSE_SENSITIVITY = 0.2

@onready var rotation_helper: Node3D = $Rotation_Helper
@onready var camera: Camera3D = $Rotation_Helper/Camera3D
@onready var spawn_point: Node3D = $/root/main/Floor/SpawnPoint

func _ready() -> void:
	Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)
	
	if spawn_point:
		call_deferred("_teleport_to_spawn")

func _teleport_to_spawn() -> void:
	global_position = spawn_point.global_position
	velocity = Vector3.ZERO # Reset any leftover velocity
	
func setSENSITIVITY(sens):
	MOUSE_SENSITIVITY = sens

func _physics_process(delta: float) -> void:
	process_input(delta)
	process_movement(delta)

func process_input(delta: float) -> void:
	# Capturing/Freeing the cursor
	if Input.is_action_just_pressed("point"):
		if Input.get_mouse_mode() == Input.MOUSE_MODE_VISIBLE:
			Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)
		else:
			Input.set_mouse_mode(Input.MOUSE_MODE_VISIBLE)

func process_movement(delta: float) -> void:
	# Get camera basis for relative movement
	var cam_xform = camera.get_global_transform()
	var input_movement_vector = Vector3.ZERO
	
	# Add gravity
	if is_on_floor():
		if Input.is_action_just_pressed("jump"):
			velocity.y = JUMP_SPEED
		else:
			velocity.y = -0.5
	else:
		velocity.y += GRAVITY * delta

	if Input.is_action_pressed("move_forward"):
		input_movement_vector.y += 1
	if Input.is_action_pressed("move_backward"):
		input_movement_vector.y -= 1
	if Input.is_action_pressed("move_left"):
		input_movement_vector.x -= 1
	if Input.is_action_pressed("move_right"):
		input_movement_vector.x += 1

	input_movement_vector = input_movement_vector.normalized()
	
	var dir = Vector3.ZERO
	dir += -cam_xform.basis.z.normalized() * input_movement_vector.y
	dir += cam_xform.basis.x.normalized() * input_movement_vector.x
	dir.y = 0
	dir = dir.normalized()

	var current_speed = MAX_SPEED
	if Input.is_action_pressed("sprint"):
		current_speed *= SPEED_MULTIPLIER

	# Horizontal velocity handling
	var hvel = velocity
	hvel.y = 0
	var target = dir * current_speed
	var acceleration = DEACCEL
	if dir != Vector3.ZERO:
		# Turn quickly when the current momentum points against the new input.
		acceleration = TURN_ACCEL if hvel.dot(dir) < 0.0 else ACCEL
	hvel = hvel.move_toward(target, acceleration * delta)
	velocity.x = hvel.x
	velocity.z = hvel.z

	move_and_slide()

func _input(event: InputEvent) -> void:
	if event is InputEventMouseMotion and Input.get_mouse_mode() == Input.MOUSE_MODE_CAPTURED:
		rotation_helper.rotate_x(deg_to_rad(event.relative.y * MOUSE_SENSITIVITY * -1))
		self.rotate_y(deg_to_rad(event.relative.x * MOUSE_SENSITIVITY * -1))

		var camera_rot = rotation_helper.rotation_degrees
		camera_rot.x = clamp(camera_rot.x, -70, 70)
		rotation_helper.rotation_degrees = camera_rot
