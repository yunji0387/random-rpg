class_name Inventory
extends RefCounted

var items: Array[Item] = []


func add_item(item: Item) -> void:
	items.append(item)


func remove_item(item: Item) -> void:
	items.erase(item)
