extends CharacterBody3D

const GRAVITY = -24.8
const MAX_SPEED = 20.0
const JUMP_SPEED = 18.0
const ACCEL = 4.5
const DEACCEL = 16.0
const MAX_SLOPE_ANGLE = 40.0

var MOUSE_SENSITIVITY = 0.05

@onready var rotation_helper: Node3D = $Rotation_Helper
@onready var camera: Camera3D = $Rotation_Helper/Camera3D

func _ready() -> void:
	Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)

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
# Add gravity
	if not is_on_floor():
		velocity.y += GRAVITY * delta
	elif Input.is_action_just_pressed("jump"): # Changed from "movement_jump" to "jump"
		velocity.y = JUMP_SPEED

	# Get camera basis for relative movement
	var cam_xform = camera.get_global_transform()
	var input_movement_vector = Vector3.ZERO

	if Input.is_action_pressed("move_forward"):
		input_movement_vector.y += 1
	if Input.is_action_pressed("move_backward"):
		input_movement_vector.y -= 1
	if Input.is_action_pressed("move_left"):
		input_movement_vector.x -= 1
	if Input.is_action_pressed("move_right"):
		input_movement_vector.x += 1
	if Input.is_action_pressed("jump"):
		input_movement_vector.z += 1

	input_movement_vector = input_movement_vector.normalized()

	var dir = Vector3.ZERO
	dir += -cam_xform.basis.z.normalized() * input_movement_vector.y
	dir += cam_xform.basis.x.normalized() * input_movement_vector.x
	dir.y = 0
	dir = dir.normalized()

	# Horizontal velocity handling
	var hvel = velocity
	hvel.y = 0

	var target = dir * MAX_SPEED

	var accel = ACCEL if dir.dot(hvel) > 0 else DEACCEL

	hvel = hvel.lerp(target, accel * delta)
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
