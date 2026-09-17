extends Control

@onready var start_button: Button = $VBoxContainer/StartButton
@onready var settings_button: Button = $VBoxContainer/SettingsButton
@onready var quit_button: Button = $VBoxContainer/QuitButton
@onready var settings_panel: PanelContainer = $SettingsPanel


func _ready() -> void:
	start_button.pressed.connect(_on_start_pressed)
	settings_button.pressed.connect(_on_settings_pressed)
	quit_button.pressed.connect(_on_quit_pressed)
	settings_panel.close_requested.connect(_on_settings_closed)


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
