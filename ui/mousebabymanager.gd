class_name MouseBabyManager
extends Node2D

@onready var player: CharacterBody3D = get_tree().get_first_node_in_group("player") as CharacterBody3D
@export var baby_mouse_scene: PackedScene
@export_range(0, 20) var child_count: int = 10:
	set(value):
		child_count = clampi(value, 0, 10)

@export_group("Shared Stats")
@export_range(0.0, 100.0) var collective_hunger: float = 100.0:
	set(value):
		collective_hunger = value
		if collective_hunger <= 0:
			player.start_death_sequence("CHILDREN")

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
	if TimeGlobal.has_signal("day_changed"):
		TimeGlobal.day_changed.connect(_on_day_changed)
	if TimeGlobal.has_signal("hour_changed"):
		TimeGlobal.hour_changed.connect(_on_hour_changed)

func spawn_mice() -> void:
	for i in range(child_count):
		var mouse_instance: MouseBabyInstance = baby_mouse_scene.instantiate()
		add_child(mouse_instance)
		active_mice.append(mouse_instance)
		
		var screen_center: Vector2 = Vector2(576.0, 324.0)
		mouse_instance.position = screen_center + Vector2(randf_range(-150, 150), randf_range(-80, 80))
		var random_variation: float = randf_range(0.9, 1.1)
		mouse_instance.scale = baby_base_scale * random_variation

func update_hunger(hours: float) -> void:
	if child_count <= 0:
		return
		
	collective_hunger -= hours * (100.0/24.0)

	for mouse in active_mice:
		if is_instance_valid(mouse):
			mouse.update_hunger_visual(collective_hunger)

func feed_mice(amount: int) -> void:
	var day_progress: float = clampf(float(TimeGlobal.day - 1) / float(adult_day_target - 1), 0.0, 1.0)
	var required_food_today: float = lerpf(5.0, 15.0, day_progress)
	
	var percent_restored: float = 100.0 / required_food_today
	var restore: float = amount * percent_restored
	
	collective_hunger = clampf(collective_hunger + restore, 0.0, 100.0)

func update_growth_and_scaling() -> void:
	var total_target_days: float = float(adult_day_target - 1)
	if total_target_days <= 0:
		total_target_days = 1.0

	var current_elapsed_days: float = float(TimeGlobal.day - 1) + (float(TimeGlobal.hour) / 24.0)
	var growth_progress: float = clampf(current_elapsed_days / total_target_days, 0.0, 1.0)
	
	for mouse in active_mice:
		if is_instance_valid(mouse):
			
			var current_target_scale: Vector2 = baby_base_scale.lerp(adult_max_scale, growth_progress)
			var seed_offset: float = sin(mouse.get_instance_id()) * 0.05 + 1.0
			mouse.scale = current_target_scale * seed_offset
			
func _on_hour_changed(_new_hour: int) -> void:
	update_hunger(1)
	update_growth_and_scaling()

func _on_day_changed(new_day: int) -> void:
	if new_day >= adult_day_target:
		on_mice_reached_adulthood()

func on_mice_reached_adulthood() -> void:
	if player:
		player.game_over_screen("WIN")
