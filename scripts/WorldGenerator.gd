extends Node3D

## Streams terrain chunks around the player and scatters simple props (trees/rocks) on them.

@export var chunk_size: float = 32.0
@export var chunk_resolution: int = 16
@export var height_scale: float = 10.0
@export var view_distance_chunks: int = 3
@export var noise_seed: int = 1337
@export var props_per_chunk: int = 14

const TerrainChunkScript := preload("res://scripts/TerrainChunk.gd")
const EnemyScene := preload("res://scenes/Enemy.tscn")
const PickupScene := preload("res://scenes/Pickup.tscn")
const NPCScene := preload("res://scenes/NPC.tscn")

var _noise := FastNoiseLite.new()
var _prop_noise := FastNoiseLite.new()
var _terrain_material: ShaderMaterial
var _trunk_mesh: Mesh
var _leaves_mesh: Mesh
var _rock_mesh: Mesh
var _chunks: Dictionary = {}
var _player: Node3D


func _ready() -> void:
	_noise.seed = noise_seed
	_noise.frequency = 0.02
	_noise.fractal_octaves = 4

	_prop_noise.seed = noise_seed + 1
	_prop_noise.frequency = 0.5

	_terrain_material = ShaderMaterial.new()
	_terrain_material.shader = preload("res://shaders/terrain.gdshader")

	_build_prop_meshes()

	_player = get_tree().get_first_node_in_group("player")
	_update_chunks()

	if _player:
		_player.global_position.y = get_height_at(_player.global_position.x, _player.global_position.z) + 2.0


func _process(_delta: float) -> void:
	if not _player:
		_player = get_tree().get_first_node_in_group("player")
	_update_chunks()


func get_height_at(world_x: float, world_z: float) -> float:
	return _noise.get_noise_2d(world_x, world_z) * height_scale


func _build_prop_meshes() -> void:
	var trunk := CylinderMesh.new()
	trunk.top_radius = 0.15
	trunk.bottom_radius = 0.22
	trunk.height = 1.6
	trunk.material = _make_material(Color(0.35, 0.22, 0.1))
	_trunk_mesh = trunk

	var leaves := SphereMesh.new()
	leaves.radius = 1.0
	leaves.height = 2.0
	leaves.material = _make_material(Color(0.15, 0.45, 0.15))
	_leaves_mesh = leaves

	var rock := SphereMesh.new()
	rock.radius = 0.5
	rock.height = 0.8
	rock.radial_segments = 6
	rock.rings = 4
	rock.material = _make_material(Color(0.5, 0.5, 0.5))
	_rock_mesh = rock


func _make_material(color: Color) -> StandardMaterial3D:
	var material := StandardMaterial3D.new()
	material.albedo_color = color
	material.roughness = 0.9
	return material


func _update_chunks() -> void:
	if not _player:
		return

	var player_chunk := Vector2i(
		int(floor(_player.global_position.x / chunk_size)),
		int(floor(_player.global_position.z / chunk_size))
	)

	var needed: Dictionary = {}
	for dz in range(-view_distance_chunks, view_distance_chunks + 1):
		for dx in range(-view_distance_chunks, view_distance_chunks + 1):
			var coord := player_chunk + Vector2i(dx, dz)
			needed[coord] = true
			if not _chunks.has(coord):
				_spawn_chunk(coord)

	var to_remove: Array = []
	for coord in _chunks.keys():
		if not needed.has(coord):
			to_remove.append(coord)
	for coord in to_remove:
		_chunks[coord].queue_free()
		_chunks.erase(coord)


func _spawn_chunk(coord: Vector2i) -> void:
	var chunk: StaticBody3D = TerrainChunkScript.new()
	add_child(chunk)
	chunk.setup(coord, chunk_size, chunk_resolution, _noise, height_scale, _terrain_material)
	_chunks[coord] = chunk
	_scatter_props(chunk, coord)
	_spawn_gameplay_entities(chunk, coord)


func _scatter_props(chunk: Node3D, coord: Vector2i) -> void:
	var rng := RandomNumberGenerator.new()
	rng.seed = hash(coord)

	var trunk_transforms: Array = []
	var leaves_transforms: Array = []
	var rock_transforms: Array = []

	for _i in props_per_chunk:
		var local_x := rng.randf_range(0.0, chunk_size)
		var local_z := rng.randf_range(0.0, chunk_size)
		var world_x := coord.x * chunk_size + local_x
		var world_z := coord.y * chunk_size + local_z
		var world_y := get_height_at(world_x, world_z)
		var density := _prop_noise.get_noise_2d(world_x, world_z)
		var yaw := rng.randf_range(0.0, TAU)
		var base_xform := Transform3D(Basis(Vector3.UP, yaw), Vector3(local_x, world_y, local_z))

		if density > 0.1:
			var scale_factor := rng.randf_range(0.8, 1.3)
			var scale_vec := Vector3(scale_factor, scale_factor, scale_factor)
			trunk_transforms.append(base_xform.scaled_local(scale_vec))
			leaves_transforms.append(base_xform.translated_local(Vector3(0, 1.6 * scale_factor, 0)).scaled_local(scale_vec))
		else:
			var rock_scale := rng.randf_range(0.5, 1.0)
			rock_transforms.append(base_xform.scaled_local(Vector3(rock_scale, rock_scale, rock_scale)))

	_add_multimesh(chunk, "TreeTrunks", _trunk_mesh, trunk_transforms)
	_add_multimesh(chunk, "TreeLeaves", _leaves_mesh, leaves_transforms)
	_add_multimesh(chunk, "Rocks", _rock_mesh, rock_transforms)


func _add_multimesh(parent: Node3D, mm_name: String, mesh: Mesh, transforms: Array) -> void:
	if transforms.is_empty():
		return
	var multimesh := MultiMesh.new()
	multimesh.transform_format = MultiMesh.TRANSFORM_3D
	multimesh.mesh = mesh
	multimesh.instance_count = transforms.size()
	for i in transforms.size():
		multimesh.set_instance_transform(i, transforms[i])

	var instance := MultiMeshInstance3D.new()
	instance.name = mm_name
	instance.multimesh = multimesh
	parent.add_child(instance)


func _spawn_gameplay_entities(chunk: Node3D, coord: Vector2i) -> void:
	var rng := RandomNumberGenerator.new()
	rng.seed = hash(coord) + 1

	# keep the player's starting chunk free of enemies
	if coord == Vector2i.ZERO:
		_spawn_npc(chunk, coord)
		return

	if rng.randf() < 0.6:
		_spawn_enemy(chunk, coord, rng)
	if rng.randf() < 0.35:
		_spawn_pickup(chunk, coord, rng)


func _spawn_enemy(chunk: Node3D, coord: Vector2i, rng: RandomNumberGenerator) -> void:
	var local_x := rng.randf_range(4.0, chunk_size - 4.0)
	var local_z := rng.randf_range(4.0, chunk_size - 4.0)
	var world_x := coord.x * chunk_size + local_x
	var world_z := coord.y * chunk_size + local_z
	var enemy := EnemyScene.instantiate()
	chunk.add_child(enemy)
	enemy.global_position = Vector3(world_x, get_height_at(world_x, world_z) + 1.0, world_z)


func _spawn_pickup(chunk: Node3D, coord: Vector2i, rng: RandomNumberGenerator) -> void:
	var local_x := rng.randf_range(0.0, chunk_size)
	var local_z := rng.randf_range(0.0, chunk_size)
	var world_x := coord.x * chunk_size + local_x
	var world_z := coord.y * chunk_size + local_z
	var pickup := PickupScene.instantiate()
	chunk.add_child(pickup)
	pickup.global_position = Vector3(world_x, get_height_at(world_x, world_z) + 0.5, world_z)
	pickup.item = _random_item(rng)


func _random_item(rng: RandomNumberGenerator) -> Item:
	var item := Item.new()
	match rng.randi_range(0, 2):
		0:
			item.item_name = "Health Potion"
			item.item_type = Item.ItemType.CONSUMABLE
			item.heal_amount = 30.0
		1:
			item.item_name = "Iron Sword"
			item.item_type = Item.ItemType.WEAPON
			item.attack_bonus = 8.0
		_:
			item.item_name = "Leather Armor"
			item.item_type = Item.ItemType.ARMOR
			item.defense_bonus = 4.0
	return item


func _spawn_npc(chunk: Node3D, coord: Vector2i) -> void:
	var npc := NPCScene.instantiate()
	chunk.add_child(npc)
	var world_x := coord.x * chunk_size + 4.0
	var world_z := coord.y * chunk_size + 4.0
	npc.global_position = Vector3(world_x, get_height_at(world_x, world_z) + 1.0, world_z)
