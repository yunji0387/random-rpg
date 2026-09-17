extends CanvasLayer

signal save_requested
signal load_requested
signal quit_requested

@onready var health_bar: ProgressBar = $Control/HealthBar
@onready var stamina_bar: ProgressBar = $Control/StaminaBar
@onready var mana_bar: ProgressBar = $Control/ManaBar
@onready var xp_bar: ProgressBar = $Control/XPBar
@onready var level_label: Label = $Control/LevelLabel
@onready var quest_label: Label = $Control/QuestLabel
@onready var time_label: Label = $Control/TimeLabel
@onready var message_label: Label = $Control/MessageLabel
@onready var inventory_panel: PanelContainer = $Control/InventoryPanel
@onready var inventory_list: ItemList = $Control/InventoryPanel/MarginContainer/VBoxContainer/InventoryList
@onready var weapon_slot_label: Label = $Control/InventoryPanel/MarginContainer/VBoxContainer/WeaponSlotLabel
@onready var armor_slot_label: Label = $Control/InventoryPanel/MarginContainer/VBoxContainer/ArmorSlotLabel
@onready var inventory_summary_label: Label = $Control/InventoryPanel/MarginContainer/VBoxContainer/InventorySummaryLabel
@onready var pause_overlay: ColorRect = $Control/PauseOverlay
@onready var pause_status_label: Label = $Control/PauseOverlay/PausePanel/MarginContainer/VBoxContainer/PauseStatusLabel
@onready var settings_panel: PanelContainer = $Control/SettingsPanel


func _ready() -> void:
	add_to_group("hud")
	process_mode = Node.PROCESS_MODE_ALWAYS
	Input.mouse_mode = Input.MOUSE_MODE_CAPTURED
	message_label.visible = false
	inventory_panel.visible = false
	inventory_list.clear()
	pause_overlay.visible = false
	settings_panel.visible = false
	settings_panel.close_requested.connect(_on_settings_closed)


func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventKey and event.pressed and event.keycode == KEY_P:
		toggle_pause_menu()
		get_viewport().set_input_as_handled()
	elif event.is_action_pressed("ui_cancel"):
		if inventory_panel.visible:
			var player = get_tree().get_first_node_in_group("player")
			if player != null and player.has_method("toggle_inventory"):
				player.toggle_inventory()
		elif settings_panel.visible:
			_on_settings_closed()
		elif pause_overlay.visible:
			toggle_pause_menu()
		else:
			toggle_pause_menu()
		get_viewport().set_input_as_handled()


func toggle_pause_menu() -> void:
	if settings_panel.visible:
		return
	if inventory_panel.visible:
		return
	var should_pause := not pause_overlay.visible
	pause_overlay.visible = should_pause
	get_tree().paused = should_pause
	Input.mouse_mode = Input.MOUSE_MODE_VISIBLE if should_pause else Input.MOUSE_MODE_CAPTURED


func _on_resume_pressed() -> void:
	toggle_pause_menu()


func _on_save_pressed() -> void:
	save_requested.emit()


func _on_load_pressed() -> void:
	load_requested.emit()


func _on_settings_pressed() -> void:
	pause_overlay.visible = false
	settings_panel.visible = true
	Input.mouse_mode = Input.MOUSE_MODE_VISIBLE


func _on_settings_closed() -> void:
	settings_panel.visible = false
	if get_tree().paused:
		pause_overlay.visible = true
		Input.mouse_mode = Input.MOUSE_MODE_VISIBLE


func _on_quit_pressed() -> void:
	quit_requested.emit()


func show_save_status(success: bool, text: String) -> void:
	pause_status_label.text = text
	if not success:
		pause_status_label.text += ""


func is_inventory_visible() -> bool:
	return inventory_panel.visible


func set_inventory_visible(inventory_should_be_visible: bool) -> void:
	inventory_panel.visible = inventory_should_be_visible
	Input.mouse_mode = Input.MOUSE_MODE_VISIBLE if inventory_should_be_visible else Input.MOUSE_MODE_CAPTURED


func set_inventory(items: Array[Item], equipped_weapon: Item, equipped_armor: Item) -> void:
	inventory_list.clear()
	for item in items:
		if item == null:
			continue
		var display_name := item.item_name
		match item.item_type:
			Item.ItemType.WEAPON:
				display_name += " [Weapon]"
			Item.ItemType.ARMOR:
				display_name += " [Armor]"
			Item.ItemType.CONSUMABLE:
				display_name += " [Consumable]"
		inventory_list.add_item(display_name)

	var weapon_text := "Weapon: Unarmed"
	if equipped_weapon != null:
		weapon_text = "Weapon: %s (+%.0f dmg)" % [equipped_weapon.item_name, equipped_weapon.attack_bonus]

	var armor_text := "Armor: Unarmored"
	if equipped_armor != null:
		armor_text = "Armor: %s (+%.0f def)" % [equipped_armor.item_name, equipped_armor.defense_bonus]

	weapon_slot_label.text = weapon_text
	armor_slot_label.text = armor_text
	inventory_summary_label.text = "Inventory: %d item(s)" % items.size()


func set_health(current: float, max_health: float) -> void:
	health_bar.max_value = max_health
	health_bar.value = current


func set_stamina(current: float, max_stamina: float) -> void:
	stamina_bar.max_value = max_stamina
	stamina_bar.value = current


func set_mana(current: float, max_mana: float) -> void:
	mana_bar.max_value = max_mana
	mana_bar.value = current


func set_xp(current: float, next_level_xp: float, level: int) -> void:
	xp_bar.max_value = next_level_xp
	xp_bar.value = current
	level_label.text = "Lv. %d" % level


func set_quest_text(text: String) -> void:
	quest_label.text = text


func set_time(text: String) -> void:
	time_label.text = text


func show_message(text: String) -> void:
	message_label.text = text
	message_label.visible = true


func hide_message() -> void:
	message_label.visible = false
