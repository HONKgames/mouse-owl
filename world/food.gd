extends Area3D

func _on_body_entered(body: Node3D) -> void:
	if body.is_in_group("player") and not body.nearby_food.has(self):
		body.nearby_food.append(self)

func _on_body_exited(body: Node3D) -> void:
	if body.is_in_group("player"):
		body.nearby_food.erase(self)
