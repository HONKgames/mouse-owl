extends CanvasLayer

@export var needs: Node

@onready var hunger_bar: ProgressBar = $VBoxContainer/HungerBar
@onready var fatigue_bar: ProgressBar = $VBoxContainer/FatigueBar

func _process(_delta: float) -> void:
	hunger_bar.value = needs.hunger
	fatigue_bar.value = needs.fatigue
