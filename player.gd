extends CharacterBody3D

const GRAVITY: float = -24.8
const MAX_SPEED: float = 8.0
const JUMP_SPEED: float = 10.0
const ACCEL: float = 10.0
const TURN_ACCEL: float = 60.0
const DECEL: float = 100.0
const SPEED_MULTIPLIER: float = 1.6
const PICKUP_TIME: float = 0.5

@export var mouse_sensitivity: float = 0.2
@export var spawn_point: Node3D

var current_den: Area3D = null
var nearby_food: Area3D
var pickup_progress: float

@onready var rotation_helper: Node3D = $Rotation_Helper
@onready var den_ui: Control = $DenUI
@onready var needs: Node = $Needs
@onready var inventory: Inventory = $Inventory
@onready var den_prompt: Label = $DenPrompt

func _ready() -> void:
	Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)
	
	if spawn_point:
		_teleport_to_spawn.call_deferred()

func _teleport_to_spawn() -> void:
	global_position = spawn_point.global_position
	velocity = Vector3.ZERO # Reset any leftover velocity

func _physics_process(delta: float) -> void:
	process_input(delta)
	if den_ui.visible:
		velocity.x = 0.0
		velocity.z = 0.0
	else:
		process_movement(delta)
	apply_gravity(delta)
	move_and_slide()

func _process(_delta: float) -> void:
	den_prompt.visible = current_den != null and not den_ui.visible

func process_input(delta: float) -> void:
	# Capturing/Freeing the cursor
	if Input.is_action_just_pressed("ui_cancel") and !den_ui.visible:
		if Input.get_mouse_mode() == Input.MOUSE_MODE_VISIBLE:
			Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)
		else:
			Input.set_mouse_mode(Input.MOUSE_MODE_VISIBLE)
	
	if Input.is_action_just_pressed("interact") and current_den:
		toggle_den()
		
	if Input.is_action_pressed("point") and nearby_food:
		pickup_progress += delta
	else:
		pickup_progress = 0.0
	if pickup_progress >= PICKUP_TIME:
		if inventory.add("food"):
			nearby_food.queue_free()
			nearby_food = null
		pickup_progress = 0.0

func apply_gravity(delta: float) -> void:
	if is_on_floor():
		if Input.is_action_just_pressed("jump") and not den_ui.visible:
			velocity.y = JUMP_SPEED
		else:
			velocity.y = -0.5
	else:
		velocity.y += GRAVITY * delta

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

func toggle_den() -> void:
	den_ui.visible = !den_ui.visible
	needs.in_den = den_ui.visible
	if den_ui.visible:
		Input.set_mouse_mode(Input.MOUSE_MODE_VISIBLE)
		current_den.stored_food += inventory.items.size()
		inventory.clear_items()
		den_ui.open(current_den, needs)
	else:
		TimeGlobal.stop_sleeping()
		Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)

func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventMouseMotion and Input.get_mouse_mode() == Input.MOUSE_MODE_CAPTURED:
		rotation_helper.rotate_x(deg_to_rad(-event.relative.y * mouse_sensitivity))
		rotate_y(deg_to_rad(-event.relative.x * mouse_sensitivity))
		rotation_helper.rotation.x = clampf(rotation_helper.rotation.x, deg_to_rad(-70), deg_to_rad(70))
