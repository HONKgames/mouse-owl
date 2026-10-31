extends Node3D

@export var sun: DirectionalLight3D
@export var moon: DirectionalLight3D
@export var time_node: Node

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	pass # Replace with function body.


func _process(delta: float) -> void:
	if not time_node:
		return
	var time_progress = time_node.get_current_time() 

	if sun:
		sun.rotation_degrees.x = (time_progress * 360.0) + 90.0
		sun.light_energy = clamp(sin(time_progress * TAU), 0.0, 1.0) * 1.5
	if moon:
		moon.rotation_degrees.x = (time_progress * 360.0) + 270.0
		moon.light_energy = clamp(-sin(time_progress * TAU), 0.0, 1.0) * 0.3
