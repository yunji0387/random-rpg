extends Control

@onready var start_button: Button = $VBoxContainer/StartButton
@onready var load_button: Button = $VBoxContainer/LoadButton
@onready var settings_button: Button = $VBoxContainer/SettingsButton
@onready var quit_button: Button = $VBoxContainer/QuitButton
@onready var settings_panel: PanelContainer = $SettingsPanel
@onready var load_slots_panel: PanelContainer = $LoadSlotsPanel
@onready var load_slot_1_button: Button = $LoadSlotsPanel/MarginContainer/VBoxContainer/LoadSlot1Button
@onready var load_slot_2_button: Button = $LoadSlotsPanel/MarginContainer/VBoxContainer/LoadSlot2Button
@onready var load_slot_3_button: Button = $LoadSlotsPanel/MarginContainer/VBoxContainer/LoadSlot3Button


func _ready() -> void:
	start_button.pressed.connect(_on_start_pressed)
	load_button.pressed.connect(_on_load_pressed)
	settings_button.pressed.connect(_on_settings_pressed)
	quit_button.pressed.connect(_on_quit_pressed)
	settings_panel.close_requested.connect(_on_settings_closed)
	load_slots_panel.visible = false


func _on_start_pressed() -> void:
	get_tree().change_scene_to_file("res://scenes/Main.tscn")


func _on_quit_pressed() -> void:
	get_tree().quit()


func _on_settings_pressed() -> void:
	$VBoxContainer.visible = false
	settings_panel.visible = true


func _on_settings_closed() -> void:
	settings_panel.visible = false
	$VBoxContainer.visible = true


func _on_load_pressed() -> void:
	$VBoxContainer.visible = false
	load_slots_panel.visible = true
	load_slot_1_button.text = SaveSystem.get_slot_status(1)
	load_slot_2_button.text = SaveSystem.get_slot_status(2)
	load_slot_3_button.text = SaveSystem.get_slot_status(3)


func _load_slot(slot: int) -> void:
	Settings.pending_load_slot = slot
	get_tree().change_scene_to_file("res://scenes/Main.tscn")


func _on_load_slot_1_pressed() -> void:
	_load_slot(1)


func _on_load_slot_2_pressed() -> void:
	_load_slot(2)


func _on_load_slot_3_pressed() -> void:
	_load_slot(3)


func _on_load_slots_close_pressed() -> void:
	load_slots_panel.visible = false
	$VBoxContainer.visible = true
