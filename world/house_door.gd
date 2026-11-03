extends Area3D

@export_file("*.tscn") var destination_scene: String = "res://world/maze.tscn"
@export var night_start_hour: int = 20
@export var night_end_hour: int = 7
@export var door_panel: Node3D
@export var open_angle: float = -90.0
@export var animation_duration: float = 0.65
var transitioning: bool = false
var is_open: bool = false
var closed_rotation: Vector3

func _ready() -> void:
	body_entered.connect(_on_body_entered)
	if door_panel:
		closed_rotation = door_panel.rotation
	if not TimeGlobal.hour_changed.is_connected(_on_hour_changed):
		TimeGlobal.hour_changed.connect(_on_hour_changed)
	_update_door(_is_night(), true)

func _exit_tree() -> void:
	if TimeGlobal.hour_changed.is_connected(_on_hour_changed):
		TimeGlobal.hour_changed.disconnect(_on_hour_changed)

func _on_hour_changed(_hour: int) -> void:
	_update_door(_is_night())

func _update_door(should_open: bool, instant: bool = false) -> void:
	if is_open == should_open and not instant:
		return
	is_open = should_open
	if not door_panel:
		return

	var target_rotation := closed_rotation
	if should_open:
		target_rotation.y += deg_to_rad(open_angle)

	if instant:
		door_panel.rotation = target_rotation
		return

	var tween := create_tween()
	tween.set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN_OUT)
	tween.tween_property(door_panel, "rotation", target_rotation, animation_duration)

func _on_body_entered(body: Node3D) -> void:
	if transitioning or not body.is_in_group("player"):
		return
	if not _is_night():
		return
	transitioning = true
	get_tree().call_deferred("change_scene_to_file", destination_scene)

func _is_night() -> bool:
	var hour: int = TimeGlobal.hour
	return hour >= night_start_hour or hour < night_end_hour
