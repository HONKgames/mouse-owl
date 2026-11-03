extends Area3D

@export var bob_height: float = 0.1
@export var bob_speed: float = 2.0
@export var spin_speed: float = 1.0

@onready var mesh: MeshInstance3D = $MeshInstance3D

var base_y: float
var phase: float
var highlight_tween: Tween

func _ready() -> void:
	base_y = mesh.position.y
	phase = randf() * TAU
	_build_mesh_collision()

func _build_mesh_collision() -> void:
	var collision := get_node_or_null("CollisionShape3D") as CollisionShape3D
	if collision == null or mesh.mesh == null:
		return
	# Derive the food's interaction shape from the same mesh that is rendered.
	# Convex mesh collision is supported reliably by Area3D and keeps the
	# player-food overlap aligned with the visible item.
	var mesh_shape := mesh.mesh.create_convex_shape()
	if mesh_shape != null:
		collision.shape = mesh_shape
		collision.transform = mesh.transform

func _process(delta: float) -> void:
	mesh.rotate_y(spin_speed * delta)
	mesh.position.y = base_y + sin((Time.get_ticks_msec() / 1000.0) * bob_speed + phase) * bob_height

func _on_body_entered(body: Node3D) -> void:
	if body.is_in_group("player") and not body.nearby_food.has(self):
		body.nearby_food.append(self)
		if highlight_tween and highlight_tween.is_valid():
			highlight_tween.kill()
		highlight_tween = create_tween()
		highlight_tween.tween_property(mesh, "scale", Vector3.ONE * 1.3, 0.15)
		highlight_tween.tween_interval(0.15)

func _on_body_exited(body: Node3D) -> void:
	if body.is_in_group("player"):
		body.nearby_food.erase(self)
		if highlight_tween and highlight_tween.is_valid():
			highlight_tween.kill()
		highlight_tween = create_tween()
		highlight_tween.tween_property(mesh, "scale", Vector3.ONE, 0.15)
		highlight_tween.tween_interval(0.15)
