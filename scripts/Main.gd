extends Node3D

@onready var player: CharacterBody3D = $Player
@onready var hud: CanvasLayer = $HUD
@onready var debug_label: Label = $HUD/Control/DebugLabel
@onready var day_night: DirectionalLight3D = $DirectionalLight3D
@onready var quest_manager: Node = $QuestManager

const STATE_NAMES: Array[String] = ["Idle", "Walk", "Run", "Crouch", "Jump", "Fall", "Roll"]


func _ready() -> void:
	player.stamina_changed.connect(hud.set_stamina)
	player.health_changed.connect(hud.set_health)
	player.mana_changed.connect(hud.set_mana)
	player.xp_changed.connect(hud.set_xp)
	quest_manager.quest_updated.connect(hud.set_quest_text)


func _process(_delta: float) -> void:
	var state_name: String = STATE_NAMES[player.state]
	debug_label.text = "Position: %s | State: %s" % [player.global_position.round(), state_name]
	hud.set_time(day_night.get_time_string())
