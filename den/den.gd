extends Control

func _input(event: InputEvent) -> void:
	if event.is_action_pressed("ui_select") or Input.is_key_pressed(KEY_SPACE):
		TimeGlobal.start_sleeping()
	elif event.is_action_released("ui_select") or not Input.is_key_pressed(KEY_SPACE):
		if not Input.is_key_pressed(KEY_SPACE):
			TimeGlobal.stop_sleeping()
