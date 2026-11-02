extends NavigationRegion3D

## Builds navigation after the procedural terrain has generated its mesh.
@export var bake_on_ready: bool = true

func _ready() -> void:
	if bake_on_ready:
		call_deferred("_bake_navigation")

func _bake_navigation() -> void:
	# Terrain creates its MeshInstance3D in _ready(). Nature generation is also
	# deferred, so wait for it before collecting obstacle geometry.
	var nature := get_node_or_null("Environment")
	if nature != null and nature.has_signal("generation_finished") and nature.get("generation_complete") != true:
		await nature.generation_finished
	else:
		await get_tree().process_frame
	bake_navigation_mesh(false)
	# Let NavigationServer publish the newly baked map before agents query it.
	await get_tree().physics_frame
