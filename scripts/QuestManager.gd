extends Node

## A minimal single-quest tracker: defeat a number of wandering enemies.

signal quest_updated(text: String)
signal quest_completed()

@export var target_kills: int = 5

var _kills := 0
var _completed := false


func _ready() -> void:
	add_to_group("quest_manager")
	quest_updated.emit(_status_text())


func register_enemy_kill() -> void:
	if _completed:
		return
	_kills += 1
	if _kills >= target_kills:
		_completed = true
		quest_completed.emit()
		var player := get_tree().get_first_node_in_group("player")
		if player and player.has_method("gain_xp"):
			player.gain_xp(100.0)
	quest_updated.emit(_status_text())


func _status_text() -> String:
	if _completed:
		return "Quest complete: Defeat wandering enemies!"
	return "Quest: Defeat wandering enemies (%d/%d)" % [_kills, target_kills]
