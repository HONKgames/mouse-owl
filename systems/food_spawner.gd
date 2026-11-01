extends Node3D

@export var food_scene: PackedScene
@export var terrain: Node
@export var count: int = 20
@export var max_food: int = 40
@export var spawn_range: float = 65.0

func _ready() -> void:
	spawn_batch(count)
	TimeGlobal.day_changed.connect(_on_day_changed)

func spawn_batch(n: int) -> void:
	for _k in range(n):
		var randx: float = randf_range(-spawn_range, spawn_range)
		var randz: float = randf_range(-spawn_range, spawn_range)
		var food: Node3D = food_scene.instantiate()
		food.position = Vector3(randx, terrain.get_height_at(randx, randz), randz)
		add_child(food)

func _on_day_changed(_day: int) -> void:
	spawn_batch(mini(count, max_food - get_child_count()))
