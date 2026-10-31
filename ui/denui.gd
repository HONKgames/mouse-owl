extends Control

@onready var time_indicator: AnimatedSprite2D = $AnimatedSprite2D
@onready var sleep_button: TextureButton = $TextureButton
@onready var vignette: TextureRect = $Vignette
var was_sleeping: bool = false

func _ready() -> void:
	if sleep_button:
		sleep_button.button_down.connect(_on_sleep_button_down)
		sleep_button.button_up.connect(_on_sleep_button_up)
	
	if vignette:
		vignette.modulate.a = 0.0
		vignette.mouse_filter = Control.MOUSE_FILTER_IGNORE
	
func _process(_delta: float) -> void:
	update_time_indicator()
	
	var is_sleeping: bool = TimeGlobal.time_scale > 10.0
	if is_sleeping != was_sleeping:
		was_sleeping = is_sleeping
		fade_sleep_effects(is_sleeping)

func update_time_indicator() -> void:
	var max_frames: int = time_indicator.sprite_frames.get_frame_count(time_indicator.animation)
	var total_minutes: int = (TimeGlobal.hour * 60) + TimeGlobal.minute
	var target_frame: int = floori((float(total_minutes) / 1440.0) * max_frames) % max_frames
	
	time_indicator.stop()
	time_indicator.frame = target_frame
	
func _on_sleep_button_down() -> void:
	TimeGlobal.start_sleeping()

func _on_sleep_button_up() -> void:
	TimeGlobal.stop_sleeping()
	
func fade_sleep_effects(active: bool) -> void:
	var tween: Tween = create_tween().set_parallel(true).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)
	
	if active:
		if vignette:
			tween.tween_property(vignette, "modulate:a", 0.4, 0.3)
		if sleep_button:
			tween.tween_property(sleep_button, "modulate", Color(1.3, 1.3, 1.0, 1.0), 0.3)
			tween.tween_property(sleep_button, "scale", Vector2(1.05, 1.05), 0.3)
	else:
		if vignette:
			tween.tween_property(vignette, "modulate:a", 0.0, 0.3)
		if sleep_button:
			tween.tween_property(sleep_button, "modulate", Color(1.0, 1.0, 1.0, 1.0), 0.3)
			tween.tween_property(sleep_button, "scale", Vector2(1.0, 1.0), 0.3)

func _input(event: InputEvent) -> void:
	if not visible:
		return
	if event.is_action_pressed("jump"):
		TimeGlobal.start_sleeping()
	elif event.is_action_released("jump"):
		TimeGlobal.stop_sleeping()
