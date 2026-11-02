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
var nearby_food: Array[Area3D] = []
var pickup_progress: float

@onready var rotation_helper: Node3D = $Rotation_Helper
@onready var den_ui: Control = $DenUI
@onready var needs: Node = $Needs
@onready var inventory: Inventory = $Inventory

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

func process_input(delta: float) -> void:
	if Input.is_action_just_pressed("ui_cancel") and !den_ui.visible:
		if Input.get_mouse_mode() == Input.MOUSE_MODE_VISIBLE:
			Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)
		else:
			Input.set_mouse_mode(Input.MOUSE_MODE_VISIBLE)
	
	if Input.is_action_just_pressed("interact") and current_den:
		toggle_den()
		
	if Input.is_action_pressed("point") and not nearby_food.is_empty() and not inventory.is_full():
		pickup_progress += delta
	elif Input.is_action_just_pressed("point") and not nearby_food.is_empty() and inventory.is_full():
		inventory.rejected.emit()
	else:
		pickup_progress = 0.0
	if pickup_progress >= PICKUP_TIME:
		if inventory.add("food"):
			var f: Area3D = nearby_food.back()
			nearby_food.erase(f)
			f.queue_free()
		pickup_progress = 0.0

func apply_gravity(delta: float) -> void:
	if is_on_floor():
		if Input.is_action_just_pressed("jump") and not den_ui.visible:
			if needs.stamina >= 10.0:
				velocity.y = JUMP_SPEED
				needs.stamina = maxf(needs.stamina - 10.0, 0.0)
				needs.stamina_changed.emit(needs.stamina)
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
		acceleration = TURN_ACCEL if hvel.dot(dir) < 0.0 else ACCEL
	hvel = hvel.move_toward(target, acceleration * delta)
	velocity.x = hvel.x
	velocity.z = hvel.z
	
	if Input.is_action_pressed("sprint") and dir != Vector3.ZERO:
		if needs.stamina > 0.0:
			current_speed *= SPEED_MULTIPLIER
			needs.stamina = maxf(needs.stamina - 25.0 * delta, 0.0)
			needs.stamina_changed.emit(needs.stamina)

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
