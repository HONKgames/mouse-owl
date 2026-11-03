extends StaticBody3D

func _ready() -> void:
	call_deferred("_attach_imported_collisions")

func _attach_imported_collisions() -> void:
	var shapes: Array[CollisionShape3D] = []
	_collect_collision_shapes(self, shapes)
	for shape in shapes:
		if shape.get_parent() != self and shape.shape != null:
			shape.reparent(self, true)

func _collect_collision_shapes(node: Node, result: Array[CollisionShape3D]) -> void:
	for child in node.get_children(true):
		if child is CollisionShape3D:
			result.append(child as CollisionShape3D)
		else:
			_collect_collision_shapes(child, result)
