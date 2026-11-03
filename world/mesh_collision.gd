class_name MeshCollision
extends StaticBody3D
## Provides a stable, solid collider for a generated tree trunk.
##
## The generated tree meshes are made from thin, disconnected triangles. A
## trimesh collider lets the player enter the gaps between those triangles and
## can leave CharacterBody3D embedded in the tree. A cylinder is a better
## gameplay collider here: it matches the trunk and always has a resolvable
## surface.

@export var trunk_radius: float = 0.4
@export var trunk_height: float = 4.0

func _ready() -> void:
	# Nature colliders live on their own layer. The player opts into this
	# layer, while flying enemies can pass through dense foliage and keep an
	# unobstructed line of sight to the player.
	collision_layer = 2
	collision_mask = 0
	call_deferred("rebuild_from_meshes")

func rebuild_from_meshes() -> void:
	var old_shapes: Array[CollisionShape3D] = []
	_collect_collision_shapes(self, old_shapes)
	for collision in old_shapes:
		collision.queue_free()

	var shape := CylinderShape3D.new()
	shape.radius = trunk_radius
	shape.height = trunk_height
	var collision := CollisionShape3D.new()
	collision.name = "TrunkCollision"
	collision.shape = shape
	# Tree roots are placed at the terrain height, so the cylinder starts at
	# the ground and extends upward from the tree origin.
	collision.position.y = trunk_height * 0.5
	add_child(collision)

func _collect_collision_shapes(node: Node, result: Array[CollisionShape3D]) -> void:
	for child in node.get_children():
		if child is CollisionShape3D:
			result.append(child as CollisionShape3D)
		else:
			_collect_collision_shapes(child, result)
