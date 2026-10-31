extends Area3D

func _on_body_entered(body: Node3D) -> void:
	if body.has_node("Needs"):
		body.get_node("Needs").in_den = true

func _on_body_exited(body: Node3D) -> void:
	if body.has_node("Needs"):
		body.get_node("Needs").in_den = false
