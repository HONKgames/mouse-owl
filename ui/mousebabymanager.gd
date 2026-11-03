class_name MouseBabyManager
extends Node2D

@onready var player: CharacterBody3D = get_tree().get_first_node_in_group("player") as CharacterBody3D
@export var baby_mouse_scene: PackedScene
@export_range(0, 100) var child_count: int = 10:
	set(value):
		child_count = clampi(value, 0, 100)

@export_group("Shared Stats")
@export_range(0.0, 100.0) var collective_hunger: float = 100.0
@export var adult_day_target: int = 7

@export_group("Depletion Multipliers")
@export var base_hunger_rate: float = 0.5
@export var night_hunger_multiplier: float = 1.8

@export_group("Growth Scale")
@export var baby_base_scale: Vector2 = Vector2(0.5, 0.5)
@export var adult_max_scale: Vector2 = Vector2(1.5, 1.5)

var active_mice: Array[MouseBabyInstance] = []

func _ready() -> void:
	spawn_mice()
	if TimeGlobal.has_signal("hour_changed"):
		TimeGlobal.day_changed.connect(_on_day_changed)

func _process(delta: float) -> void:
	if collective_hunger == 0.0:
		player.game_over_screen("CHILDREN")
		return
	update_hunger(delta)
	update_growth_and_scaling()

func spawn_mice() -> void:
	for i in range(child_count):
		var mouse_instance: MouseBabyInstance = baby_mouse_scene.instantiate()
		add_child(mouse_instance)
		active_mice.append(mouse_instance)
		
		var screen_center: Vector2 = Vector2(576.0, 324.0)
		mouse_instance.position = screen_center + Vector2(randf_range(-150, 150), randf_range(-80, 80))
		var random_variation: float = randf_range(0.9, 1.1)
		mouse_instance.scale = baby_base_scale * random_variation

func update_hunger(delta: float) -> void:
	if child_count <= 0:
		return

	var is_night: bool = TimeGlobal.hour >= 20 or TimeGlobal.hour < 7
	var current_night_mult: float = night_hunger_multiplier if is_night else 1.0

	var age_factor: float = 1.0 + (float(TimeGlobal.day) / float(adult_day_target))
	var population_factor: float = 1.0 + (child_count * 0.05)

	var hunger_increase: float = base_hunger_rate * current_night_mult * age_factor * population_factor * delta * TimeGlobal.time_scale
	collective_hunger = clampf(collective_hunger + hunger_increase, 0.0, 100.0)

	for mouse in active_mice:
		if is_instance_valid(mouse):
			mouse.update_hunger_visual(collective_hunger)

func feed_mice(amount: int) -> void:
	var hunger_restored_per_food: float = 10.0
	var reduction: float = amount * hunger_restored_per_food
	collective_hunger = clampf(collective_hunger - reduction, 0.0, 100.0)

func update_growth_and_scaling() -> void:
	var growth_progress: float = clampf(float(TimeGlobal.day - 1) / float(adult_day_target - 1), 0.0, 1.0)
	
	for mouse in active_mice:
		if is_instance_valid(mouse):
			var current_target_scale: Vector2 = baby_base_scale.lerp(adult_max_scale, growth_progress)
			var seed_offset: float = sin(mouse.get_instance_id()) * 0.05 + 1.0
			mouse.scale = current_target_scale * seed_offset

func _on_day_changed(new_day: int) -> void:
	if new_day >= adult_day_target:
		on_mice_reached_adulthood()

func on_mice_reached_adulthood() -> void:
	if player:
		player.game_over_screen("WIN")
