extends Node3D

## Toggles rain on/off on a random timer and follows the player, adjusting fog while it rains.

@export var environment_path: NodePath
@export var min_clear_seconds: float = 25.0
@export var max_clear_seconds: float = 50.0
@export var min_rain_seconds: float = 12.0
@export var max_rain_seconds: float = 25.0

@onready var rain: GPUParticles3D = $Rain

var _environment: Environment
var _player: Node3D
var _timer := 0.0
var _is_raining := false


func _ready() -> void:
	if environment_path != NodePath():
		var world_env: WorldEnvironment = get_node(environment_path)
		_environment = world_env.environment
	rain.emitting = false
	_timer = randf_range(min_clear_seconds, max_clear_seconds)


func _process(delta: float) -> void:
	if not _player:
		_player = get_tree().get_first_node_in_group("player")
	if _player:
		global_position = _player.global_position + Vector3(0, 15.0, 0)

	_timer -= delta
	if _timer <= 0.0:
		_is_raining = not _is_raining
		rain.emitting = _is_raining
		_timer = randf_range(min_rain_seconds, max_rain_seconds) if _is_raining else randf_range(min_clear_seconds, max_clear_seconds)

	if _environment:
		_environment.fog_enabled = _is_raining or _environment.fog_density > 0.001
		var target_fog := 0.025 if _is_raining else 0.0
		_environment.fog_density = lerp(_environment.fog_density, target_fog, delta)
