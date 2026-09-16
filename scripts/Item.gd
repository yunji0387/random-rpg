class_name Item
extends Resource

enum ItemType { WEAPON, ARMOR, CONSUMABLE }

@export var item_name: String = "Item"
@export var item_type: ItemType = ItemType.CONSUMABLE
@export var attack_bonus: float = 0.0
@export var defense_bonus: float = 0.0
@export var heal_amount: float = 0.0
