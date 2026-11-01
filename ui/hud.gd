extends CanvasLayer

@export var needs: Node
@export var inventory: Inventory

@onready var hunger_bar: ProgressBar = $VBoxContainer/HungerBar
@onready var fatigue_bar: ProgressBar = $VBoxContainer/FatigueBar
@onready var slots: Array[Node] = $Hotbar.get_children()

func _ready() -> void:
	inventory.changed.connect(_on_inventory_changed)
	_on_inventory_changed()

func _process(_delta: float) -> void:
	hunger_bar.value = needs.hunger
	fatigue_bar.value = needs.fatigue

func _on_inventory_changed() -> void:
	for x in slots.size():
		slots[x].get_node("TextureRect").visible = x < inventory.items.size()
