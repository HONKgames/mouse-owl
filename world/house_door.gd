extends Area3D

@export_file("*.tscn") var destination_scene: String = "res://world/maze.tscn"
@export var night_start_hour: int = 20
@export var night_end_hour: int = 7
var transitioning: bool = false

func _ready() -> void:
	body_entered.connect(_on_body_entered)

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
