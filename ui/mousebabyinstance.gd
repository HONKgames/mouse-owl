class_name MouseBabyInstance
extends CharacterBody2D

@export var jump_velocity_min: float = -200.0
@export var jump_velocity_max: float = -500.0
@export var horizontal_speed_range: float = 100.0
@export var jump_interval_min: float = 0.1
@export var jump_interval_max: float = 0.5

var gravity: float = ProjectSettings.get_setting("physics/2d/default_gravity")
var jump_timer: float = 0.0

@onready var sprite: Sprite2D = $Sprite2D

func _ready() -> void:
	_reset_jump_timer()

func _physics_process(delta: float) -> void:
	if TimeGlobal.time_scale > 1.5:
		if not is_on_floor():
			velocity.y += gravity * delta
		else:
			velocity.x = move_toward(velocity.x, 0, 500 * delta)
			rotation = move_toward(rotation, 0.0, 15.0 * delta)
		move_and_slide()
		return

	if not is_on_floor():
		velocity.y += gravity * delta
		rotation += velocity.x * delta * 0.01
	else:
		velocity.x = move_toward(velocity.x, 0, 500 * delta)
		rotation = move_toward(rotation, 0.0, 15.0 * delta)
		
		jump_timer -= delta
		if jump_timer <= 0.0:
			pop_jump()

	move_and_slide()

func pop_jump(power: float = 1.0) -> void:
	velocity.y = randf_range(jump_velocity_min, jump_velocity_max) * power
	velocity.x = randf_range(-horizontal_speed_range, horizontal_speed_range) * power
	
	if randf() > 0.5:
		sprite.flip_h = not sprite.flip_h
		
	if velocity.x != 0:
		sprite.flip_h = velocity.x < 0

	_reset_jump_timer()

func _reset_jump_timer() -> void:
	jump_timer = randf_range(jump_interval_min, jump_interval_max)

func is_hit(screen_pos: Vector2) -> bool:
	var local: Vector2 = sprite.to_local(screen_pos)
	return sprite.get_rect().has_point(local)

func update_hunger_visual(hunger_0_to_100: float) -> void:
	if sprite:
		sprite.modulate = Color.WHITE.lerp(Color(0.5, 0.5, 0.5), hunger_0_to_100 / 100.0)
