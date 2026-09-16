extends CharacterBody3D

## Simple patrol -> chase -> attack AI.

const MAX_HEALTH := 40.0
const MOVE_SPEED := 3.0
const PATROL_SPEED := 1.5
const CHASE_RADIUS := 10.0
const ATTACK_RADIUS := 1.6
const ATTACK_DAMAGE := 8.0
const ATTACK_COOLDOWN := 1.2
const GRAVITY := 9.8

signal died(enemy: Node)

@onready var mesh: MeshInstance3D = $MeshInstance3D

var health := MAX_HEALTH
var _player: Node3D
var _home_position: Vector3
var _patrol_target: Vector3
var _attack_timer := 0.0
var _base_color := Color.WHITE
var _material: StandardMaterial3D


func _ready() -> void:
	add_to_group("enemy")
	_home_position = global_position
	_patrol_target = _home_position
	_player = get_tree().get_first_node_in_group("player")

	# duplicate so hit-flash doesn't affect every enemy sharing this scene's material
	var base_material := mesh.get_active_material(0)
	if base_material is StandardMaterial3D:
		_material = base_material.duplicate()
		mesh.set_surface_override_material(0, _material)
		_base_color = _material.albedo_color


func _physics_process(delta: float) -> void:
	if not is_on_floor():
		velocity.y -= GRAVITY * delta

	if not _player:
		_player = get_tree().get_first_node_in_group("player")

	_attack_timer = max(_attack_timer - delta, 0.0)

	if _player:
		var to_player := _player.global_position - global_position
		var distance := to_player.length()
		if distance <= CHASE_RADIUS:
			_chase(to_player, distance)
		else:
			_patrol()
	else:
		_patrol()

	move_and_slide()


func _chase(to_player: Vector3, distance: float) -> void:
	if distance > ATTACK_RADIUS:
		var direction := Vector3(to_player.x, 0.0, to_player.z).normalized()
		velocity.x = direction.x * MOVE_SPEED
		velocity.z = direction.z * MOVE_SPEED
	else:
		velocity.x = 0.0
		velocity.z = 0.0
		if _attack_timer <= 0.0:
			_attack_timer = ATTACK_COOLDOWN
			if _player.has_method("take_damage"):
				_player.take_damage(ATTACK_DAMAGE)


func _patrol() -> void:
	var to_target := _patrol_target - global_position
	if Vector2(to_target.x, to_target.z).length() < 0.5:
		var angle := randf_range(0.0, TAU)
		var radius := randf_range(3.0, 8.0)
		_patrol_target = _home_position + Vector3(cos(angle) * radius, 0.0, sin(angle) * radius)
	var direction := Vector3(to_target.x, 0.0, to_target.z).normalized()
	velocity.x = direction.x * PATROL_SPEED
	velocity.z = direction.z * PATROL_SPEED


func take_damage(amount: float, _source: Node = null) -> void:
	health -= amount
	_flash_hit()
	if health <= 0.0:
		died.emit(self)
		if _player and _player.has_method("gain_xp"):
			_player.gain_xp(25.0)
		var quest_manager := get_tree().get_first_node_in_group("quest_manager")
		if quest_manager and quest_manager.has_method("register_enemy_kill"):
			quest_manager.register_enemy_kill()
		queue_free()


func _flash_hit() -> void:
	if not _material:
		return
	_material.albedo_color = Color(1.0, 0.2, 0.2)
	await get_tree().create_timer(0.15).timeout
	if is_instance_valid(_material):
		_material.albedo_color = _base_color
