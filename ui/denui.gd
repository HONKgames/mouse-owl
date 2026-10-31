extends Control

@onready var time_indicator: AnimatedSprite2D = $AnimatedSprite2D
@onready var sleep_button: TextureButton = $TextureButton

func _ready() -> void:
	if sleep_button:
		sleep_button.button_down.connect(_on_sleep_button_down)
		sleep_button.button_up.connect(_on_sleep_button_up)
	update_time_indicator()
	
func _process(_delta: float) -> void:
	update_time_indicator()

func update_time_indicator() -> void:
	var max_frames = time_indicator.sprite_frames.get_frame_count(time_indicator.animation)
	var total_minutes = (TimeGlobal.hour * 60) + TimeGlobal.minute
	var target_frame = floori((float(total_minutes) / 1440.0) * max_frames) % max_frames
	
	time_indicator.stop()
	time_indicator.frame = target_frame
	
func _on_sleep_button_down() -> void:
	TimeGlobal.start_sleeping()

func _on_sleep_button_up() -> void:
	TimeGlobal.stop_sleeping()


func _input(event: InputEvent) -> void:
	if event.is_action_pressed("ui_select") or Input.is_key_pressed(KEY_SPACE):
		TimeGlobal.start_sleeping()
	elif event.is_action_released("ui_select") or not Input.is_key_pressed(KEY_SPACE):
		if not Input.is_key_pressed(KEY_SPACE):
			TimeGlobal.stop_sleeping()
