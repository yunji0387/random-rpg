extends StaticBody3D

var chunk_coord: Vector2i
var mesh_instance: MeshInstance3D
var collision_shape: CollisionShape3D


func setup(p_chunk_coord: Vector2i, chunk_size: float, resolution: int, noise: FastNoiseLite, height_scale: float, material: Material) -> void:
	chunk_coord = p_chunk_coord
	mesh_instance = MeshInstance3D.new()
	collision_shape = CollisionShape3D.new()
	add_child(mesh_instance)
	add_child(collision_shape)

	position = Vector3(chunk_coord.x * chunk_size, 0.0, chunk_coord.y * chunk_size)

	var verts_per_side := resolution + 1
	var vertex_count := verts_per_side * verts_per_side
	var step := chunk_size / resolution

	var vertices := PackedVector3Array()
	var uvs := PackedVector2Array()
	var normals := PackedVector3Array()
	var heights := PackedFloat32Array()
	vertices.resize(vertex_count)
	uvs.resize(vertex_count)
	normals.resize(vertex_count)
	heights.resize(vertex_count)

	for z in verts_per_side:
		for x in verts_per_side:
			var idx := z * verts_per_side + x
			var local_x := x * step
			var local_z := z * step
			var world_x := chunk_coord.x * chunk_size + local_x
			var world_z := chunk_coord.y * chunk_size + local_z
			var h := noise.get_noise_2d(world_x, world_z) * height_scale
			heights[idx] = h
			vertices[idx] = Vector3(local_x, h, local_z)
			uvs[idx] = Vector2(float(x) / resolution, float(z) / resolution)

	# central-difference normals computed from neighboring sample heights
	for z in verts_per_side:
		for x in verts_per_side:
			var idx := z * verts_per_side + x
			var hl: float = heights[idx - 1] if x > 0 else heights[idx]
			var hr: float = heights[idx + 1] if x < resolution else heights[idx]
			var hd: float = heights[idx - verts_per_side] if z > 0 else heights[idx]
			var hu: float = heights[idx + verts_per_side] if z < resolution else heights[idx]
			normals[idx] = Vector3(hl - hr, 2.0 * step, hd - hu).normalized()

	var indices := PackedInt32Array()
	for z in resolution:
		for x in resolution:
			var i0 := z * verts_per_side + x
			var i1 := i0 + 1
			var i2 := i0 + verts_per_side
			var i3 := i2 + 1
			indices.append(i0)
			indices.append(i2)
			indices.append(i1)
			indices.append(i1)
			indices.append(i2)
			indices.append(i3)

	var arrays := []
	arrays.resize(Mesh.ARRAY_MAX)
	arrays[Mesh.ARRAY_VERTEX] = vertices
	arrays[Mesh.ARRAY_NORMAL] = normals
	arrays[Mesh.ARRAY_TEX_UV] = uvs
	arrays[Mesh.ARRAY_INDEX] = indices

	var array_mesh := ArrayMesh.new()
	array_mesh.add_surface_from_arrays(Mesh.PRIMITIVE_TRIANGLES, arrays)
	array_mesh.surface_set_material(0, material)
	mesh_instance.mesh = array_mesh

	var shape := HeightMapShape3D.new()
	shape.map_width = verts_per_side
	shape.map_depth = verts_per_side
	shape.map_data = heights
	collision_shape.shape = shape
	collision_shape.position = Vector3(chunk_size / 2.0, 0.0, chunk_size / 2.0)
	collision_shape.scale = Vector3(step, 1.0, step)


func height_at_local(local_x: float, local_z: float, noise: FastNoiseLite, height_scale: float) -> float:
	return noise.get_noise_2d(position.x + local_x, position.z + local_z) * height_scale
