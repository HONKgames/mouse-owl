extends Node3D

signal generation_finished

var generation_complete: bool = false

@export var terrain_path: NodePath = NodePath("Terrain")
@export var tree_region_path: NodePath = NodePath("TreeSpawnRegion")
@export var pumpkin_region_path: NodePath = NodePath("PumpkingSpawnRegion")
@export var house_path: NodePath = NodePath("House")

@export_group("Trees")
@export var tree_count: int = 50
@export_range(0.0, 100.0, 0.5) var tree_inner_radius: float = 8.0
@export_range(0.0, 100.0, 0.5) var tree_outer_radius: float = 40.0
@export_range(0.0, 1.0, 0.05) var small_tree_probability: float = 0.4
@export_range(1.0, 6.0, 0.1) var tree_scale_min: float = 2.5
@export_range(1.0, 6.0, 0.1) var tree_scale_max: float = 3.5

@export_group("Pumpkins")
@export var pumpkin_count: int = 50
@export_range(0.0, 100.0, 0.5) var pumpkin_inner_radius: float = 46.0
@export_range(0.0, 100.0, 0.5) var pumpkin_outer_radius: float = 65.0

@export_group("Grass")
@export var grass_count: int = 1000
@export_range(0.0, 100.0, 0.5) var grass_inner_radius: float = 5.0
@export_range(0.0, 100.0, 0.5) var grass_outer_radius: float = 65.0
@export var house_exclusion_half_size: Vector2 = Vector2(10.0, 8.0)
@export var house_exclusion_margin: float = 2.0
@onready var grouping: Node3D = $GrassSpawnRegion
@onready var grass: Sprite3D = $GrassSpawnRegion/Grass

## Number of objects to create before yielding back to the main loop.
## Keeping this small prevents procedural trees from blocking scene loading.
@export_range(1, 50, 1) var spawn_batch_size: int = 10

@export_group("Night tree colors")
@export var night_foliage_color: Color = Color(0.12, 0.02, 0.22, 1.0)
@export var night_fresnel_color: Color = Color(0.3, 0.04, 0.42, 1.0)
@export var night_trunk_color: Color = Color(0.24, 0.035, 0.28, 1.0)

var rng := RandomNumberGenerator.new()
var house_center: Vector2 = Vector2.ZERO
var house_exclusion_enabled: bool = false
var last_night_factor: float = -1.0

func _ready() -> void:
	rng.randomize()
	var terrain: Node = get_node(terrain_path)
	# Defer the expensive procedural instantiation until the scene is loaded.
	call_deferred("_spawn_nature", terrain)

func _spawn_nature(terrain: Node) -> void:
	_cache_house_exclusion()
	await _spawn_trees(terrain)
	await _spawn_pumpkins(terrain)

	await _spawn_grass(terrain)

	generation_complete = true
	last_night_factor = -1.0
	_update_tree_colors(_get_night_factor())
	generation_finished.emit()

func _process(_delta: float) -> void:
	_update_tree_colors(_get_night_factor())

func _get_night_factor() -> float:
	# Matches atmosphere.gd: moonlight begins at 18:00, peaks at midnight,
	# and fades back out by 06:00.
	return clampf(-cos((TimeGlobal.get_time() - 0.5) * TAU), 0.0, 1.0)

func _update_tree_colors(night_factor: float) -> void:
	if absf(night_factor - last_night_factor) < 0.005:
		return
	last_night_factor = night_factor
	var region := get_node_or_null(tree_region_path)
	if region == null:
		return
	for tree in region.get_children():
		if tree.name.begins_with("Tree_"):
			_apply_tree_color(tree, night_factor)

func _apply_tree_color(node: Node, night_factor: float) -> void:
	for child in node.get_children(true):
		if child is MeshInstance3D:
			_apply_mesh_color(child as MeshInstance3D, night_factor)
			if child.mesh != null:
				for surface in range(child.mesh.get_surface_count()):
					_apply_material_color(child.mesh.surface_get_material(surface), night_factor)
		_apply_tree_color(child, night_factor)

func _apply_mesh_color(mesh_instance: MeshInstance3D, night_factor: float) -> void:
	var material := mesh_instance.material_override
	if material is ShaderMaterial:
		material = material.duplicate()
		mesh_instance.material_override = material
	elif mesh_instance.mesh != null:
		for surface in range(mesh_instance.mesh.get_surface_count()):
			var surface_material := mesh_instance.mesh.surface_get_material(surface)
			if surface_material is ShaderMaterial:
				material = surface_material.duplicate()
				mesh_instance.material_override = material
				break
	_apply_material_color(material, night_factor)

func _apply_material_color(material: Material, night_factor: float) -> void:
	if material is ShaderMaterial:
		var shader_material := material as ShaderMaterial
		var day_foliage_color := Color(0.941, 0.235, 0.055, 1.0)
		var day_fresnel_color := Color(0.961, 0.514, 0.09, 1.0)
		shader_material.set_shader_parameter("foliage_colour", day_foliage_color.lerp(night_foliage_color, night_factor))
		shader_material.set_shader_parameter("fresnel_colour", day_fresnel_color.lerp(night_fresnel_color, night_factor))
		shader_material.set_shader_parameter("color_strength", lerpf(1.0, 0.18, night_factor))
	elif material is StandardMaterial3D:
		(material as StandardMaterial3D).albedo_color = Color.WHITE.lerp(night_trunk_color, night_factor)

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
	var tree := MeshCollision.new()
	tree.name = tree_name
	# Generate at native scale, then enlarge the baked result so the procedural
	# generator does not process oversized geometry for every tree.
	var visual_scale := rng.randf_range(tree_scale_min, tree_scale_max)
	tree.scale = template.scale * visual_scale
	parent.add_child(tree)
	for child: Node in template.get_children(true):
		tree.add_child(child.duplicate())
	return tree

func _spawn_pumpkins(terrain: Node) -> void:
	var region: Node3D = get_node(pumpkin_region_path)
	var template: Node3D = region.get_node("Pumpkin_1")

	for index in range(pumpkin_count):
		var point := _random_clear_annulus_point(pumpkin_inner_radius, pumpkin_outer_radius)
		if is_inf(point.x):
			continue
		var pumpkin: Node3D = template.duplicate()
		pumpkin.name = "Pumpkin_%02d" % index
		region.add_child(pumpkin)
		# The template is hidden so it does not render in the spawn region. Each
		# spawned pumpkin must be explicitly shown after duplication.
		pumpkin.visible = true
		_place_on_terrain(pumpkin, terrain, point)
		if (index + 1) % spawn_batch_size == 0:
			await get_tree().process_frame

	template.queue_free()
	
func _spawn_grass(terrain: Node) -> void:
	if not grass:
		return
	
	var base_half_height: float = 0.5
	if grass.texture:
		base_half_height = (grass.texture.get_height() * grass.pixel_size) * 0.5

	for index in range(grass_count):
		var point := _random_clear_annulus_point(grass_inner_radius, grass_outer_radius)
		if is_inf(point.x):
			continue
		var grass_instance: Sprite3D = grass.duplicate() as Sprite3D
		grass_instance.name = "Grass_%02d" % index
		grass_instance.visible = true
		
		var random_scale: float = rng.randf_range(0.7, 1.3)
		grass_instance.scale = Vector3(random_scale, random_scale, random_scale)
		
		grouping.add_child(grass_instance)
		
		var terrain_height: float = terrain.get_height_at(point.x, point.y)
		var vertical_offset := base_half_height * random_scale * 0.9
		
		grass_instance.global_position = Vector3(point.x, terrain_height + vertical_offset, point.y)
		
		if (index + 1) % spawn_batch_size == 0:
			await get_tree().process_frame

	grass.queue_free()

func _place_on_terrain(item: Node3D, terrain: Node, point: Vector2) -> void:
	item.global_position = Vector3(point.x, terrain.get_height_at(point.x, point.y), point.y)

func _random_annulus_point(inner_radius: float, outer_radius: float) -> Vector2:
	var angle := rng.randf_range(0.0, TAU)
	var radius := sqrt(rng.randf_range(inner_radius * inner_radius, outer_radius * outer_radius))
	return Vector2(cos(angle), sin(angle)) * radius

func _random_clear_annulus_point(inner_radius: float, outer_radius: float) -> Vector2:
	for attempt in range(64):
		var point := _random_annulus_point(inner_radius, outer_radius)
		if not _is_inside_house(point):
			return point
	return Vector2(INF, INF)

func _cache_house_exclusion() -> void:
	var house := get_node_or_null(house_path) as Node3D
	if house == null:
		return
	house_center = Vector2(house.global_position.x, house.global_position.z)
	house_exclusion_enabled = true

func _is_inside_house(point: Vector2) -> bool:
	if not house_exclusion_enabled:
		return false
	var half_size := house_exclusion_half_size + Vector2.ONE * house_exclusion_margin
	return absf(point.x - house_center.x) <= half_size.x and absf(point.y - house_center.y) <= half_size.y
