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

## Number of objects to create before yielding back to the main loop.
## Keeping this small prevents procedural trees from blocking scene loading.
@export_range(1, 50, 1) var spawn_batch_size: int = 10

var rng := RandomNumberGenerator.new()

func _ready() -> void:
	rng.randomize()
	var terrain: Node = get_node(terrain_path)
	# Defer the expensive procedural instantiation until the scene is loaded.
	call_deferred("_spawn_nature", terrain)

func _spawn_nature(terrain: Node) -> void:
	await _spawn_trees(terrain)
	await _spawn_pumpkins(terrain)

func _spawn_trees(terrain: Node) -> void:
	var region: Node3D = get_node(tree_region_path)
	var small_template: Node3D = region.get_node("SmallTree")
	var medium_template: Node3D = region.get_node("MediumTree")
	# Tree3D is a native procedural node. Its duplicate() path regenerates the
	# complete tree, so bake each template once and clone its generated children.
	small_template.visible = false
	medium_template.visible = false

	for index in range(tree_count):
		var template: Node3D = small_template if rng.randf() < small_tree_probability else medium_template
		var tree: Node3D = _clone_baked_tree(template, region, "Tree_%02d" % index)
		_place_on_terrain(tree, terrain, _random_annulus_point(tree_inner_radius, tree_outer_radius))
		if (index + 1) % spawn_batch_size == 0:
			await get_tree().process_frame

	small_template.queue_free()
	medium_template.queue_free()

func _clone_baked_tree(template: Node3D, parent: Node3D, tree_name: String) -> Node3D:
	var tree := Node3D.new()
	tree.name = tree_name
	parent.add_child(tree)
	# Tree3D keeps its mesh and collision nodes as internal children.
	for child: Node in template.get_children(true):
		tree.add_child(child.duplicate())
	return tree

func _spawn_pumpkins(terrain: Node) -> void:
	var region: Node3D = get_node(pumpkin_region_path)
	var template: Node3D = region.get_node("Pumpkin_1")

	for index in range(pumpkin_count):
		var pumpkin: Node3D = template.duplicate()
		pumpkin.name = "Pumpkin_%02d" % index
		region.add_child(pumpkin)
		_place_on_terrain(pumpkin, terrain, _random_annulus_point(pumpkin_inner_radius, pumpkin_outer_radius))
		if (index + 1) % spawn_batch_size == 0:
			await get_tree().process_frame

	template.queue_free()

func _place_on_terrain(item: Node3D, terrain: Node, point: Vector2) -> void:
	item.global_position = Vector3(point.x, terrain.get_height_at(point.x, point.y), point.y)

func _random_annulus_point(inner_radius: float, outer_radius: float) -> Vector2:
	var angle := rng.randf_range(0.0, TAU)
	var radius := sqrt(rng.randf_range(inner_radius * inner_radius, outer_radius * outer_radius))
	return Vector2(cos(angle), sin(angle)) * radius
