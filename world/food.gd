extends Area3D

func _on_body_entered(body: Node3D) -> void:
	if body.is_in_group("player"):
		body.nearby_food = self
	print("near food")

func _on_body_exited(body: Node3D) -> void:
	if body.is_in_group("player") and body.nearby_food == self:
		body.nearby_food = null
	print("not near food")
