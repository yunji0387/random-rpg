extends CharacterBody3D

enum State { IDLE, WALK, RUN, CROUCH, JUMP, FALL, ROLL }

const WALK_SPEED := 5.0
const RUN_SPEED := 8.0
const CROUCH_SPEED := 2.5
const ROLL_SPEED := 10.0
const ROLL_DURATION := 0.35
const ROLL_COOLDOWN := 0.8
const JUMP_VELOCITY := 4.5
const MOUSE_SENSITIVITY := 0.0025
const GRAVITY := 9.8

const MAX_STAMINA := 100.0
const STAMINA_DRAIN_PER_SEC := 25.0
const STAMINA_ROLL_COST := 20.0
const STAMINA_REGEN_PER_SEC := 15.0
const STAMINA_REGEN_DELAY := 0.6

const STAND_HEIGHT := 1.8
const CROUCH_HEIGHT := 1.0

const BASE_MAX_HEALTH := 100.0
const BASE_MAX_MANA := 50.0
const BASE_ATTACK_DAMAGE := 10.0
const BASE_DEFENSE := 0.0
const ATTACK_RANGE := 2.5
const ATTACK_COOLDOWN := 0.6

signal stamina_changed(current: float, max_stamina: float)
signal health_changed(current: float, max_health: float)
signal mana_changed(current: float, max_mana: float)
signal xp_changed(current: float, next_level_xp: float, level: int)
signal state_changed(new_state: int)
signal died()

@onready var spring_arm: SpringArm3D = $SpringArm3D
@onready var camera: Camera3D = $SpringArm3D/Camera3D
@onready var mesh: MeshInstance3D = $MeshInstance3D
@onready var collision_shape: CollisionShape3D = $CollisionShape3D

var _camera_pitch := 0.0
var stamina := MAX_STAMINA
var _stamina_regen_timer := 0.0
var state: State = State.IDLE

var _is_crouching := false
var _is_rolling := false
var _roll_timer := 0.0
var _roll_cooldown_timer := 0.0
var _roll_direction := Vector3.ZERO

var max_health := BASE_MAX_HEALTH
var health := BASE_MAX_HEALTH
var max_mana := BASE_MAX_MANA
var mana := BASE_MAX_MANA
var attack_damage := BASE_ATTACK_DAMAGE
var defense := BASE_DEFENSE
var level := 1
var xp := 0.0
var xp_to_next_level := 100.0

var inventory := Inventory.new()
var equipped_weapon: Item
var equipped_armor: Item
var _attack_cooldown_timer := 0.0


func _ready() -> void:
	add_to_group("player")
	Input.mouse_mode = Input.MOUSE_MODE_CAPTURED
	# avoid mutating the shared capsule resources across instances
	collision_shape.shape = collision_shape.shape.duplicate()
	mesh.mesh = mesh.mesh.duplicate()
	health_changed.emit(health, max_health)
	mana_changed.emit(mana, max_mana)
	xp_changed.emit(xp, xp_to_next_level, level)


func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventMouseMotion and Input.mouse_mode == Input.MOUSE_MODE_CAPTURED:
		rotate_y(-event.relative.x * MOUSE_SENSITIVITY)
		_camera_pitch = clamp(_camera_pitch - event.relative.y * MOUSE_SENSITIVITY, -1.2, 1.2)
		spring_arm.rotation.x = _camera_pitch

	if event.is_action_pressed("ui_cancel"):
		if Input.mouse_mode == Input.MOUSE_MODE_CAPTURED:
			Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
		else:
			Input.mouse_mode = Input.MOUSE_MODE_CAPTURED

	if event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
		_attempt_attack()


func _physics_process(delta: float) -> void:
	if not is_on_floor():
		velocity.y -= GRAVITY * delta

	_handle_crouch()
	_handle_roll(delta)

	if _is_rolling:
		velocity.x = _roll_direction.x * ROLL_SPEED
		velocity.z = _roll_direction.z * ROLL_SPEED
	else:
		_handle_movement(delta)

	if Input.is_physical_key_pressed(KEY_SPACE) and is_on_floor() and not _is_crouching and not _is_rolling:
		velocity.y = JUMP_VELOCITY

	move_and_slide()
	_attack_cooldown_timer = max(_attack_cooldown_timer - delta, 0.0)
	_update_stamina(delta)
	_update_state()
	_update_visuals(delta)


func _get_input_dir() -> Vector2:
	var input_dir := Vector2.ZERO
	if Input.is_physical_key_pressed(KEY_W):
		input_dir.y -= 1.0
	if Input.is_physical_key_pressed(KEY_S):
		input_dir.y += 1.0
	if Input.is_physical_key_pressed(KEY_A):
		input_dir.x -= 1.0
	if Input.is_physical_key_pressed(KEY_D):
		input_dir.x += 1.0
	return input_dir.normalized()


func _handle_crouch() -> void:
	var wants_crouch := Input.is_physical_key_pressed(KEY_CTRL) and not _is_rolling
	if wants_crouch == _is_crouching:
		return
	_is_crouching = wants_crouch
	var target_height := CROUCH_HEIGHT if _is_crouching else STAND_HEIGHT
	var capsule_shape: CapsuleShape3D = collision_shape.shape
	capsule_shape.height = target_height
	collision_shape.position.y = target_height / 2.0
	var capsule_mesh: CapsuleMesh = mesh.mesh
	capsule_mesh.height = target_height
	mesh.position.y = target_height / 2.0


func _handle_roll(delta: float) -> void:
	if _roll_cooldown_timer > 0.0:
		_roll_cooldown_timer -= delta

	if _is_rolling:
		_roll_timer -= delta
		if _roll_timer <= 0.0:
			_is_rolling = false
		return

	if Input.is_physical_key_pressed(KEY_R) and _roll_cooldown_timer <= 0.0 and stamina >= STAMINA_ROLL_COST and is_on_floor():
		var input_dir := _get_input_dir()
		var move_dir := transform.basis * Vector3(input_dir.x, 0, input_dir.y)
		_roll_direction = move_dir.normalized() if move_dir.length() > 0.0 else -transform.basis.z
		_is_rolling = true
		_roll_timer = ROLL_DURATION
		_roll_cooldown_timer = ROLL_COOLDOWN
		stamina = max(stamina - STAMINA_ROLL_COST, 0.0)
		_stamina_regen_timer = STAMINA_REGEN_DELAY


func _handle_movement(_delta: float) -> void:
	var input_dir := _get_input_dir()
	var direction := (transform.basis * Vector3(input_dir.x, 0, input_dir.y)).normalized()

	var wants_sprint := Input.is_physical_key_pressed(KEY_SHIFT) and not _is_crouching and stamina > 0.0 and direction.length() > 0.0
	var speed := WALK_SPEED
	if _is_crouching:
		speed = CROUCH_SPEED
	elif wants_sprint:
		speed = RUN_SPEED

	if wants_sprint:
		stamina = max(stamina - STAMINA_DRAIN_PER_SEC * _delta, 0.0)
		_stamina_regen_timer = STAMINA_REGEN_DELAY

	if direction.length() > 0.0:
		velocity.x = direction.x * speed
		velocity.z = direction.z * speed
	else:
		velocity.x = move_toward(velocity.x, 0, speed)
		velocity.z = move_toward(velocity.z, 0, speed)


func _update_stamina(delta: float) -> void:
	if _stamina_regen_timer > 0.0:
		_stamina_regen_timer -= delta
	elif stamina < MAX_STAMINA:
		stamina = min(stamina + STAMINA_REGEN_PER_SEC * delta, MAX_STAMINA)
	stamina_changed.emit(stamina, MAX_STAMINA)


func _update_state() -> void:
	var previous_state := state
	var horizontal_speed := Vector2(velocity.x, velocity.z).length()

	if _is_rolling:
		state = State.ROLL
	elif not is_on_floor():
		state = State.JUMP if velocity.y > 0.0 else State.FALL
	elif _is_crouching:
		state = State.CROUCH
	elif horizontal_speed > RUN_SPEED - 0.5:
		state = State.RUN
	elif horizontal_speed > 0.2:
		state = State.WALK
	else:
		state = State.IDLE

	if state != previous_state:
		state_changed.emit(state)


func _update_visuals(delta: float) -> void:
	var target_scale := Vector3.ONE
	var target_fov := 75.0
	match state:
		State.CROUCH:
			target_scale = Vector3(1.0, 0.75, 1.0)
		State.ROLL:
			target_scale = Vector3(1.1, 0.6, 1.1)
			target_fov = 90.0
		State.JUMP:
			target_scale = Vector3(0.9, 1.15, 0.9)
		State.FALL:
			target_scale = Vector3(1.05, 0.95, 1.05)
		State.RUN:
			target_fov = 85.0
	mesh.scale = mesh.scale.lerp(target_scale, delta * 10.0)
	camera.fov = lerp(camera.fov, target_fov, delta * 5.0)


func _attempt_attack() -> void:
	if _attack_cooldown_timer > 0.0:
		return
	_attack_cooldown_timer = ATTACK_COOLDOWN
	for enemy in get_tree().get_nodes_in_group("enemy"):
		if not is_instance_valid(enemy):
			continue
		if global_position.distance_to(enemy.global_position) <= ATTACK_RANGE and enemy.has_method("take_damage"):
			enemy.take_damage(attack_damage, self)


func take_damage(amount: float, _source: Node = null) -> void:
	var mitigated: float = max(amount - defense, 1.0)
	health = max(health - mitigated, 0.0)
	health_changed.emit(health, max_health)
	if health <= 0.0:
		_die()


func heal(amount: float) -> void:
	health = min(health + amount, max_health)
	health_changed.emit(health, max_health)


func gain_xp(amount: float) -> void:
	xp += amount
	while xp >= xp_to_next_level:
		xp -= xp_to_next_level
		level += 1
		xp_to_next_level *= 1.25
		max_health += 20.0
		max_mana += 10.0
		health = max_health
		mana = max_mana
	xp_changed.emit(xp, xp_to_next_level, level)
	health_changed.emit(health, max_health)
	mana_changed.emit(mana, max_mana)


func collect_item(item: Item) -> void:
	inventory.add_item(item)
	match item.item_type:
		Item.ItemType.WEAPON, Item.ItemType.ARMOR:
			equip_item(item)
		Item.ItemType.CONSUMABLE:
			heal(item.heal_amount)
			inventory.remove_item(item)


func equip_item(item: Item) -> void:
	match item.item_type:
		Item.ItemType.WEAPON:
			equipped_weapon = item
			attack_damage = BASE_ATTACK_DAMAGE + item.attack_bonus
		Item.ItemType.ARMOR:
			equipped_armor = item
			defense = BASE_DEFENSE + item.defense_bonus


func _die() -> void:
	died.emit()
	health = max_health
	health_changed.emit(health, max_health)
	velocity = Vector3.ZERO
	global_position = Vector3(global_position.x, global_position.y + 5.0, global_position.z)
