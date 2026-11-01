extends Area3D

var stored_food: int = 0

func _on_body_entered(body: Node3D) -> void:
	if body.is_in_group("player"):
		body.current_den = self

func _on_body_exited(body: Node3D) -> void:
	if body.is_in_group("player"):
		body.current_den = null
