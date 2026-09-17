extends Node

const SETTINGS_PATH := "user://random_rpg_settings.json"

var mouse_sensitivity: float = 0.0025
var brightness: float = 1.0


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	load_settings()


func set_mouse_sensitivity(value: float) -> void:
	mouse_sensitivity = clampf(value, 0.001, 0.01)
	save_settings()


func set_brightness(value: float) -> void:
	brightness = clampf(value, 0.5, 1.5)
	_apply_brightness()
	save_settings()


func apply_current_settings() -> void:
	_apply_brightness()


func load_settings() -> void:
	if not FileAccess.file_exists(SETTINGS_PATH):
		_apply_brightness()
		return
	var file := FileAccess.open(SETTINGS_PATH, FileAccess.READ)
	if file == null:
		_apply_brightness()
		return
	var parsed: Variant = JSON.parse_string(file.get_as_text())
	file.close()
	if parsed is Dictionary:
		mouse_sensitivity = clampf(float(parsed.get("mouse_sensitivity", mouse_sensitivity)), 0.001, 0.01)
		brightness = clampf(float(parsed.get("brightness", brightness)), 0.5, 1.5)
	_apply_brightness()


func save_settings() -> void:
	var file := FileAccess.open(SETTINGS_PATH, FileAccess.WRITE)
	if file != null:
		file.store_string(JSON.stringify({
			"mouse_sensitivity": mouse_sensitivity,
			"brightness": brightness
		}))
		file.close()


func _apply_brightness() -> void:
	var world_environment := get_tree().get_first_node_in_group("world_environment")
	if world_environment == null or world_environment.environment == null:
		return
	world_environment.environment.adjustment_enabled = true
	world_environment.environment.adjustment_brightness = brightness
