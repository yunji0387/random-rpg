class_name SaveSystem
extends Node

const LEGACY_SAVE_PATH := "user://random_rpg_save.json"
const SAVE_PATH_TEMPLATE := "user://random_rpg_save_%d.json"
const SAVE_VERSION := 1

signal save_completed(success: bool, message: String)


func _ready() -> void:
	add_to_group("save_system")
	process_mode = Node.PROCESS_MODE_ALWAYS


func save_game(player: Node, quest_manager: Node, day_night: Node, slot: int = 1) -> bool:
	if not _is_valid_slot(slot):
		save_completed.emit(false, "Invalid save slot")
		return false
	var data := {
		"version": SAVE_VERSION,
		"player": _player_to_dict(player),
		"quest": _quest_to_dict(quest_manager),
		"day_night": {
			"time_of_day": day_night.time_of_day,
			"day_count": day_night.day_count
		}
	}
	var file := FileAccess.open(_slot_path(slot), FileAccess.WRITE)
	if file == null:
		save_completed.emit(false, "Unable to open save file")
		return false
	file.store_string(JSON.stringify(data))
	file.close()
	save_completed.emit(true, "Game saved to Slot %d" % slot)
	return true


func load_game(player: Node, quest_manager: Node, day_night: Node, slot: int = 1) -> bool:
	if not _is_valid_slot(slot):
		save_completed.emit(false, "Invalid save slot")
		return false
	var path := _slot_path(slot)
	if slot == 1 and not FileAccess.file_exists(path) and FileAccess.file_exists(LEGACY_SAVE_PATH):
		path = LEGACY_SAVE_PATH
	if not FileAccess.file_exists(path):
		save_completed.emit(false, "No save in Slot %d" % slot)
		return false
	var file := FileAccess.open(path, FileAccess.READ)
	if file == null:
		save_completed.emit(false, "Unable to read save file")
		return false
	var parsed: Variant = JSON.parse_string(file.get_as_text())
	file.close()
	if not parsed is Dictionary or int(parsed.get("version", 0)) != SAVE_VERSION:
		save_completed.emit(false, "Save file is not compatible")
		return false

	_apply_player(player, parsed.get("player", {}))
	_apply_quest(quest_manager, parsed.get("quest", {}))
	_apply_day_night(day_night, parsed.get("day_night", {}))
	save_completed.emit(true, "Loaded Slot %d" % slot)
	return true


static func has_save(slot: int = 1) -> bool:
	if not _is_valid_slot(slot):
		return false
	return FileAccess.file_exists(_slot_path(slot)) or (slot == 1 and FileAccess.file_exists(LEGACY_SAVE_PATH))


static func get_slot_status(slot: int) -> String:
	return "Slot %d - %s" % [slot, "Available" if has_save(slot) else "Empty"]


static func _is_valid_slot(slot: int) -> bool:
	return slot >= 1 and slot <= 3


static func _slot_path(slot: int) -> String:
	return SAVE_PATH_TEMPLATE % slot


func _player_to_dict(player: Node) -> Dictionary:
	var inventory_data: Array[Dictionary] = []
	for item in player.inventory.items:
		inventory_data.append(_item_to_dict(item))
	return {
		"position": [player.global_position.x, player.global_position.y, player.global_position.z],
		"rotation_y": player.rotation.y,
		"camera_pitch": player.get("_camera_pitch"),
		"health": player.health,
		"max_health": player.max_health,
		"mana": player.mana,
		"max_mana": player.max_mana,
		"stamina": player.stamina,
		"level": player.level,
		"xp": player.xp,
		"xp_to_next_level": player.xp_to_next_level,
		"attack_damage": player.attack_damage,
		"defense": player.defense,
		"inventory": inventory_data,
		"equipped_weapon": _item_to_dict(player.equipped_weapon),
		"equipped_armor": _item_to_dict(player.equipped_armor)
	}


func _item_to_dict(item: Item) -> Dictionary:
	if item == null:
		return {}
	return {
		"item_name": item.item_name,
		"item_type": item.item_type,
		"attack_bonus": item.attack_bonus,
		"defense_bonus": item.defense_bonus,
		"heal_amount": item.heal_amount
	}


func _item_from_dict(data: Dictionary) -> Item:
	var item := Item.new()
	item.item_name = str(data.get("item_name", "Item"))
	item.item_type = int(data.get("item_type", Item.ItemType.CONSUMABLE)) as Item.ItemType
	item.attack_bonus = float(data.get("attack_bonus", 0.0))
	item.defense_bonus = float(data.get("defense_bonus", 0.0))
	item.heal_amount = float(data.get("heal_amount", 0.0))
	return item


func _apply_player(player: Node, data: Dictionary) -> void:
	var position_data: Array = data.get("position", [0.0, 1.0, 0.0])
	if position_data.size() >= 3:
		player.global_position = Vector3(float(position_data[0]), float(position_data[1]), float(position_data[2]))
	player.rotation.y = float(data.get("rotation_y", player.rotation.y))
	player.set("_camera_pitch", float(data.get("camera_pitch", 0.0)))
	player.spring_arm.rotation.x = player.get("_camera_pitch")
	player.health = float(data.get("health", player.health))
	player.max_health = float(data.get("max_health", player.max_health))
	player.mana = float(data.get("mana", player.mana))
	player.max_mana = float(data.get("max_mana", player.max_mana))
	player.stamina = float(data.get("stamina", player.stamina))
	player.level = int(data.get("level", player.level))
	player.xp = float(data.get("xp", player.xp))
	player.xp_to_next_level = float(data.get("xp_to_next_level", player.xp_to_next_level))
	player.attack_damage = float(data.get("attack_damage", player.attack_damage))
	player.defense = float(data.get("defense", player.defense))
	player.inventory.items.clear()
	for item_data in data.get("inventory", []):
		if item_data is Dictionary:
			player.inventory.add_item(_item_from_dict(item_data))
	var weapon_data: Dictionary = data.get("equipped_weapon", {})
	var armor_data: Dictionary = data.get("equipped_armor", {})
	player.equipped_weapon = _item_from_dict(weapon_data) if not weapon_data.is_empty() else null
	player.equipped_armor = _item_from_dict(armor_data) if not armor_data.is_empty() else null
	player.health_changed.emit(player.health, player.max_health)
	player.mana_changed.emit(player.mana, player.max_mana)
	player.stamina_changed.emit(player.stamina, player.MAX_STAMINA)
	player.xp_changed.emit(player.xp, player.xp_to_next_level, player.level)
	player._refresh_inventory_ui()


func _quest_to_dict(quest_manager: Node) -> Dictionary:
	return {
		"kills": quest_manager.get("_kills"),
		"completed": quest_manager.get("_completed")
	}


func _apply_quest(quest_manager: Node, data: Dictionary) -> void:
	quest_manager.set("_kills", int(data.get("kills", 0)))
	quest_manager.set("_completed", bool(data.get("completed", false)))
	quest_manager.quest_updated.emit(quest_manager._status_text())


func _apply_day_night(day_night: Node, data: Dictionary) -> void:
	day_night.time_of_day = float(data.get("time_of_day", day_night.time_of_day))
	day_night.day_count = int(data.get("day_count", day_night.day_count))
