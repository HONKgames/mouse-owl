class_name Inventory
extends Node

signal changed
signal rejected
signal selected_changed

@export var max_items: int = 3
const FOOD_VALUE: float = 25.0

var items: Array[String]
var selected: int = 0

func select(i: int) -> void:
	i = posmod(i, max_items)
	if i == selected:
		return
	selected = i
	selected_changed.emit()

func selected_item() -> String:
	return items[selected] if selected < items.size() else ""

func remove_at(i: int) -> void:
	if i >= items.size() or i < 0:
		return
	items.remove_at(i)
	changed.emit()

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
