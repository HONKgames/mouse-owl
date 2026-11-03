extends CharacterBody3D
class_name MousePlayer

const GRAVITY: float = -24.8
const MAX_SPEED: float = 8.0
const JUMP_SPEED: float = 10.0
const ACCEL: float = 10.0
const TURN_ACCEL: float = 60.0
const DECEL: float = 100.0
const SPEED_MULTIPLIER: float = 1.6
const PICKUP_TIME: float = 0.5
const EAT_TIME: float = 1.0
const TIME_TO_DEATH: float = 5.0

@export var mouse_sensitivity: float = 0.2
@export var spawn_point: Node3D

@onready var rotation_helper: Node3D = $Rotation_Helper
@onready var camera_3D: Camera3D = $Rotation_Helper/Camera3D
@onready var den_ui: Control = $DenUI
@onready var needs: Node = $Needs
@onready var inventory: Inventory = $Inventory
@onready var pickup_sound: AudioStreamPlayer = $PickupSound
@onready var death_model: Node3D = $MouseModel
@onready var death_vignette: Control = $DeathVignette
@onready var game_over: Node2D = $GameOver
@onready var restart_button: Button = $GameOver/restart
@onready var death_hunger: Node2D = $GameOver/death_hunger
@onready var death_children: Node2D = $GameOver/death_children
@onready var death_enemy: Node2D = $GameOver/death_enemy
@onready var win: Node2D = $GameOver/win
@onready var death_floor: TextureRect = $GameOver/Floor
@onready var hud: CanvasLayer = $Hud

@onready var den_prompt: Label = $DenPrompt

var current_den: Area3D = null
var nearby_food: Array[Area3D] = []
var pickup_progress: float = 0.0
var eat_progress: float = 0.0
var is_dead: bool = false
var death_timer: float = 0.0
var death_camera: Camera3D = null

func _ready() -> void:
	add_to_group("player")
	Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)
	
	if death_vignette and death_vignette.texture is GradientTexture2D:
		death_vignette.texture.gradient = death_vignette.texture.gradient.duplicate()
	if restart_button:
		restart_button.pressed.connect(_reset)
	
	if spawn_point:
		_teleport_to_spawn.call_deferred()
		
func _process(delta: float) -> void:
	RenderingServer.global_shader_parameter_set("player_position", global_position)
	den_prompt.visible = current_den != null and not den_ui.visible
	if is_dead:
		return
		
	var max_cap: float = maxf(0.0, 100.0 - needs.fatigue - needs.hunger)
	
	if max_cap <= 0.0:
		death_timer += delta
		
		var darken_progress: float = clampf(death_timer / TIME_TO_DEATH, 0.0, 1.0)
		
		if death_vignette:
			death_vignette.visible = true
			
			death_vignette.modulate.a = clampf(darken_progress * 1.5, 0.0, 1.0)
			
			var texture: GradientTexture2D = death_vignette.texture as GradientTexture2D
			if texture and texture.gradient:
				var current_offset: float = lerpf(1.0, 0.2, darken_progress)
				texture.gradient.set_offset(1, current_offset)
			
		if death_timer >= TIME_TO_DEATH:
			start_death_sequence("HUNGER")
	else:
		death_timer = maxf(death_timer - delta * 3.0, 0.0)
		
		var darken_progress: float = clampf(death_timer / TIME_TO_DEATH, 0.0, 1.0)
		
		if death_vignette:
			death_vignette.modulate.a = clampf(darken_progress * 1.5, 0.0, 1.0)
			
			var texture: GradientTexture2D = death_vignette.texture as GradientTexture2D
			if texture and texture.gradient:
				var current_offset: float = lerpf(1.0, 0.2, darken_progress)
				texture.gradient.set_offset(1, current_offset)
				
			if death_timer <= 0.0:
				death_vignette.visible = false

func _teleport_to_spawn() -> void:
	global_position = spawn_point.global_position
	velocity = Vector3.ZERO # Reset any leftover velocity

func _physics_process(delta: float) -> void:
	if is_dead:
		return
		
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
	
	if den_ui.visible:
		pickup_progress = 0.0
		return
	
	if Input.is_action_just_pressed("slot_1"):
		inventory.select(0)
	if Input.is_action_just_pressed("slot_2"):
		inventory.select(1)
	if Input.is_action_just_pressed("slot_3"):
		inventory.select(2)
	
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
			pickup_sound.pitch_scale = randf_range(0.9, 1.1)
			#pickup_sound.play() we need a pickup sfx lol
		pickup_progress = 0.0
	if Input.is_action_pressed("interact") and current_den == null and inventory.selected_item() != "":
		eat_progress += delta
	else:
		eat_progress = 0.0
	if eat_progress >= EAT_TIME:
		needs.eat(Inventory.FOOD_VALUE)
		inventory.remove_at(inventory.selected)
		eat_progress = 0.0

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
	if TimeGlobal.time_scale > 1.0:
		return
		
	den_ui.visible = !den_ui.visible
	hud.set_hotbar_visible(!den_ui.visible)
	needs.in_den = den_ui.visible
	if den_ui.visible:
		Input.set_mouse_mode(Input.MOUSE_MODE_VISIBLE)
		var deposited: int = inventory.items.size()
		
		if current_den:
			current_den.stored_food += deposited
			
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
	elif not is_dead and not den_ui.visible:
		if event.is_action_pressed("slot_next"):
			inventory.select(inventory.selected + 1)
		elif event.is_action_pressed("slot_prev"):
			inventory.select(inventory.selected - 1)

func start_death_sequence(type: String) -> void:
	is_dead = true
	hud.visible = false
	den_ui.visible = false
	death_model.visible = true
	death_model.position = rotation_helper.position
	death_vignette.visible = false
	Input.set_mouse_mode(Input.MOUSE_MODE_VISIBLE)
	
	rotation_helper.rotation = Vector3.ZERO
	rotation_helper.rotation.x = deg_to_rad(-90)
	
	if camera_3D:
		var tween: Tween = create_tween().set_parallel(true)
		tween.tween_property(camera_3D, "position:z", 5.0, 3.0)
	
	await get_tree().create_timer(5.0).timeout
	game_over_screen(type)

func game_over_screen(type: String) -> void:
	hud.visible = false
	den_ui.visible = false
	Input.set_mouse_mode(Input.MOUSE_MODE_VISIBLE)
	TimeGlobal.stop_sleeping()
	is_dead = true
	game_over.visible = true
	var texture: GradientTexture2D = death_floor.texture as GradientTexture2D
	var floor_color: Color
	
	if type.contains("HUNGER"):
		death_hunger.visible = true
		floor_color = Color.from_hsv(0.361, 0.484, 0.809, 0.502)
	elif type.contains("CHILDREN"):
		death_children.visible = true
		floor_color = Color.from_hsv(0.361, 0.484, 0.809, 0.502)
	elif type.contains("ENEMY"):
		death_enemy.visible = true
		floor_color = Color.from_hsv(0.012, 0.796, 0.797, 0.502)
	elif type.contains("WIN"):
		win.visible = true
		floor_color = Color.from_hsv(0.122, 0.006, 0.709, 0.502)
	
	if texture and texture.gradient and floor_color:
		texture.gradient.set_color(0, floor_color)

func _reset() -> void:
	get_tree().reload_current_scene()
