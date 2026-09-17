extends Node3D

@onready var player: CharacterBody3D = $Player
@onready var hud: CanvasLayer = $HUD
@onready var debug_label: Label = $HUD/Control/DebugLabel
@onready var day_night: DirectionalLight3D = $DirectionalLight3D
@onready var quest_manager: Node = $QuestManager
@onready var save_system: SaveSystem = $SaveSystem

const STATE_NAMES: Array[String] = ["Idle", "Walk", "Run", "Crouch", "Jump", "Fall", "Roll"]


func _ready() -> void:
	Settings.apply_current_settings()
	player.stamina_changed.connect(hud.set_stamina)
	player.health_changed.connect(hud.set_health)
	player.mana_changed.connect(hud.set_mana)
	player.xp_changed.connect(hud.set_xp)
	quest_manager.quest_updated.connect(hud.set_quest_text)
	hud.save_requested.connect(save_game)
	hud.load_requested.connect(load_game)
	hud.quit_requested.connect(_quit_to_menu)
	save_system.save_completed.connect(hud.show_save_status)


func _process(_delta: float) -> void:
	var state_name: String = STATE_NAMES[player.state]
	debug_label.text = "Position: %s | State: %s" % [player.global_position.round(), state_name]
	hud.set_time(day_night.get_time_string())


func save_game() -> void:
	save_system.save_game(player, quest_manager, day_night)


func load_game() -> void:
	save_system.load_game(player, quest_manager, day_night)


func _quit_to_menu() -> void:
	get_tree().paused = false
	get_tree().change_scene_to_file("res://scenes/ui/MainMenu.tscn")
