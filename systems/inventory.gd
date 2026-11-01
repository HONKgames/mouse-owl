class_name Inventory
extends Node

@export var max_items: int = 3

var items: Array[String]

func add(item: String) -> bool:
	if items.size() >= max_items:
		return false
	items.append(item)
	return true
