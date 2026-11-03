class_name MeshCollision
extends StaticBody3D
## Builds collision geometry directly from the MeshInstance3D children of this body.

func _ready() -> void:
	call_deferred("rebuild_from_meshes")

func rebuild_from_meshes() -> void:
	var meshes: Array[MeshInstance3D] = []
	_collect_meshes(self, meshes)
	var old_shapes: Array[CollisionShape3D] = []
	_collect_collision_shapes(self, old_shapes)
	for collision in old_shapes:
		collision.queue_free()
	for mesh_instance in meshes:
		if mesh_instance.mesh == null:
			continue
		var shape := mesh_instance.mesh.create_trimesh_shape()
		if shape == null:
			continue
		var collision := CollisionShape3D.new()
		collision.name = "%sMeshCollision" % mesh_instance.name
		collision.shape = shape
		collision.transform = global_transform.affine_inverse() * mesh_instance.global_transform
		add_child(collision)

func _collect_meshes(node: Node, result: Array[MeshInstance3D]) -> void:
	for child in node.get_children():
		if child is MeshInstance3D:
			result.append(child as MeshInstance3D)
		_collect_meshes(child, result)

func _collect_collision_shapes(node: Node, result: Array[CollisionShape3D]) -> void:
	for child in node.get_children():
		if child is CollisionShape3D:
			result.append(child as CollisionShape3D)
		else:
			_collect_collision_shapes(child, result)
