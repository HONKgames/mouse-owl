extends Node3D

@export var food_scene: PackedScene
@export var terrain: Node
@export var count: int = 20
@export var max_food: int = 40
@export var spawn_range: float = 65.0
@export var min_spacing: float = 3.0

func _ready() -> void:
	spawn_batch(count)
	TimeGlobal.day_changed.connect(_on_day_changed)

func spawn_batch(n: int) -> void:
	for _k in range(n):
		var p: Vector2 = _pick_spot()
		var food: Node3D = food_scene.instantiate()
		food.position = Vector3(p.x, terrain.get_height_at(p.x, p.y), p.y)
		add_child(food)

func _pick_spot() -> Vector2:
	var cand: Vector2 = Vector2.ZERO
	for _k in range(10):
		var randx: float = randf_range(-spawn_range, spawn_range)
		var randz: float = randf_range(-spawn_range, spawn_range)
		cand = Vector2(randx, randz)
		var ok: bool = true
		for spot: Node3D in terrain.flat_spots:
			if cand.distance_squared_to(Vector2(spot.global_position.x, spot.global_position.z)) < terrain.flat_radius * terrain.flat_radius:
				ok = false
				break
		if ok:
			for f: Node3D in get_children():
				if cand.distance_squared_to(Vector2(f.position.x, f.position.z)) < min_spacing * min_spacing:
					ok = false
					break
		if ok:
			return cand
	return cand

func _on_day_changed(_day: int) -> void:
	spawn_batch(mini(count, max_food - get_child_count()))
