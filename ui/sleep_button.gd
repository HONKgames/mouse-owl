extends TextureButton

func _ready() -> void:
	button_down.connect(_on_button_down)
	button_up.connect(_on_button_up)

func _on_button_down() -> void:
	TimeGlobal.start_sleeping()
	
func _on_button_up() -> void:
	TimeGlobal.stop_sleeping()
