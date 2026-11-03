extends Area3D

@export var bob_height: float = 0.1
@export var bob_speed: float = 2.0
@export var spin_speed: float = 1.0

@onready var mesh: Node3D = $mushroomnew

var base_y: float
var phase: float
var highlight_tween: Tween

func _ready() -> void:
	base_y = mesh.position.y
	phase = randf() * TAU

func _process(delta: float) -> void:
	mesh.rotate_y(spin_speed * delta)
	mesh.position.y = base_y + sin((Time.get_ticks_msec() / 1000.0) * bob_speed + phase) * bob_height

func _on_body_entered(body: Node3D) -> void:
	if body.is_in_group("player") and not body.nearby_food.has(self):
		body.nearby_food.append(self)
		if highlight_tween and highlight_tween.is_valid():
			highlight_tween.kill()
		highlight_tween = create_tween()
		#highlight_tween.tween_property(mesh, "scale", Vector3.ONE * 1.05, 0.15)
		highlight_tween.tween_interval(0.15)

func _on_body_exited(body: Node3D) -> void:
	if body.is_in_group("player"):
		body.nearby_food.erase(self)
		if highlight_tween and highlight_tween.is_valid():
			highlight_tween.kill()
		highlight_tween = create_tween()
		#highlight_tween.tween_property(mesh, "scale", Vector3.ONE, 0.15)
		highlight_tween.tween_interval(0.15)
