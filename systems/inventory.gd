class_name Inventory
extends Node

signal changed
signal rejected

@export var max_items: int = 3

var items: Array[String]

func is_full() -> bool:
	return items.size() >= max_items

func add(item: String) -> bool:
	if is_full():
		return false
	items.append(item)
	changed.emit()
	return true

func clear_items() -> void:
	items.clear()
	changed.emit()
