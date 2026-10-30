extends Node

signal hour_changed(hour: int )
signal day_changed(day: int)

@export var seconds_per_hour: float = 60.0
var second: float = 0.0
var minute: int = 0
var hour: int = 8
var day: int = 1

var time_scale: float = 1.0
var target_time_scale: float = 1.0
@export var max_time_scale: float = 20.0
@export var ramp_speed: float = 10.0

func _process(delta: float) -> void:
	time_scale = move_toward(time_scale, target_time_scale, ramp_speed * delta)
	second += delta * time_scale
	
	while second >= (seconds_per_hour / 60):
		second -= (seconds_per_hour / 60)
		advance_minute()
		
func advance_minute() -> void:
	minute += 1
	if minute >= 60:
		minute = 0
		advance_hour()
		
func advance_hour() -> void:
	hour += 1
	print("Hour passed: ", hour, " | Day: ", day)
	emit_signal("hour_changed", hour)
	if hour >= 24:
		hour = 0
		day += 1
		print("--- NEW DAY: ", day, " ---")
		emit_signal("day_changed", day)
		
func start_sleeping() -> void:
	target_time_scale = max_time_scale
	
func stop_sleeping() -> void:
	target_time_scale = 1.0

func _input(event: InputEvent) -> void:
	if event.is_action_pressed("ui_select") or Input.is_key_pressed(KEY_SPACE):
		start_sleeping()
	elif event.is_action_released("ui_select") or not Input.is_key_pressed(KEY_SPACE):
		if not Input.is_key_pressed(KEY_SPACE):
			stop_sleeping()
