extends CanvasLayer

@onready var health_bar: ProgressBar = $Control/HealthBar
@onready var stamina_bar: ProgressBar = $Control/StaminaBar
@onready var mana_bar: ProgressBar = $Control/ManaBar
@onready var xp_bar: ProgressBar = $Control/XPBar
@onready var level_label: Label = $Control/LevelLabel
@onready var quest_label: Label = $Control/QuestLabel
@onready var time_label: Label = $Control/TimeLabel
@onready var message_label: Label = $Control/MessageLabel


func _ready() -> void:
	add_to_group("hud")
	message_label.visible = false


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
