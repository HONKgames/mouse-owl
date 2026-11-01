class_name Inventory
extends Node

signal changed

@export var max_items: int = 3

var items: Array[String]

func add(item: String) -> bool:
	if items.size() >= max_items:
		return false
	items.append(item)
	changed.emit()
	return true

func clear_items() -> void:
	items.clear()
	changed.emit()
