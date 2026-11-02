extends Node3D

@export var terrain_path: NodePath = NodePath("Terrain")
@export var tree_region_path: NodePath = NodePath("TreeSpawnRegion")
@export var pumpkin_region_path: NodePath = NodePath("PumpkingSpawnRegion")

@export_group("Trees")
@export var tree_count: int = 80
@export_range(0.0, 100.0, 0.5) var tree_inner_radius: float = 8.0
@export_range(0.0, 100.0, 0.5) var tree_outer_radius: float = 40.0
@export_range(0.0, 1.0, 0.05) var small_tree_probability: float = 0.4

@export_group("Pumpkins")
@export var pumpkin_count: int = 50
@export_range(0.0, 100.0, 0.5) var pumpkin_inner_radius: float = 46.0
@export_range(0.0, 100.0, 0.5) var pumpkin_outer_radius: float = 65.0

var rng := RandomNumberGenerator.new()

func _ready() -> void:
	rng.randomize()
	var terrain: Node = get_node(terrain_path)
	_spawn_trees(terrain)
	_spawn_pumpkins(terrain)

func _spawn_trees(terrain: Node) -> void:
	var region: Node3D = get_node(tree_region_path)
	var small_template: Node3D = region.get_node("SmallTree")
	var medium_template: Node3D = region.get_node("MediumTree")

	for index in tree_count:
		var template: Node3D = small_template if rng.randf() < small_tree_probability else medium_template
		var tree: Node3D = template.duplicate()
		tree.name = "Tree_%02d" % index
		region.add_child(tree)
		_place_on_terrain(tree, terrain, _random_annulus_point(tree_inner_radius, tree_outer_radius))

	small_template.queue_free()
	medium_template.queue_free()

func _spawn_pumpkins(terrain: Node) -> void:
	var region: Node3D = get_node(pumpkin_region_path)
	var template: Node3D = region.get_node("Pumpkin_1")

	for index in pumpkin_count:
		var pumpkin: Node3D = template.duplicate()
		pumpkin.name = "Pumpkin_%02d" % index
		region.add_child(pumpkin)
		_place_on_terrain(pumpkin, terrain, _random_annulus_point(pumpkin_inner_radius, pumpkin_outer_radius))

	template.queue_free()

func _place_on_terrain(item: Node3D, terrain: Node, point: Vector2) -> void:
	item.global_position = Vector3(point.x, terrain.get_height_at(point.x, point.y), point.y)

func _random_annulus_point(inner_radius: float, outer_radius: float) -> Vector2:
	var angle := rng.randf_range(0.0, TAU)
	var radius := sqrt(rng.randf_range(inner_radius * inner_radius, outer_radius * outer_radius))
	return Vector2(cos(angle), sin(angle)) * radius
