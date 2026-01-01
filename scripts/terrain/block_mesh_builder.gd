class_name BlockMeshBuilder
extends RefCounted
## Builds Minecraft-style stepped block terrain from heightmap.
## Each grid point becomes a flat square block at its height.
## Side faces are added where adjacent blocks have different heights.

var height_scale: float = 25.0
var terrain_scale: float = 1.5
var block_size: float = 1.0


func build_mesh(heightmap: PackedFloat32Array, grid_size: int) -> ArrayMesh:
	var st := SurfaceTool.new()
	st.begin(Mesh.PRIMITIVE_TRIANGLES)
	
	var half_size := float(grid_size - 1) / 2.0
	
	# Generate blocks
	for z in range(grid_size - 1):
		for x in range(grid_size - 1):
			var height := _get_height(heightmap, grid_size, x, z)
			var world_y := height * height_scale * terrain_scale
			
			# Block origin in world space (centered)
			var world_x := (float(x) - half_size) * terrain_scale
			var world_z := (float(z) - half_size) * terrain_scale
			var size := terrain_scale
			
			# Get color based on height
			var color := _height_to_color(world_y)
			
			# Top face (always visible)
			_add_top_face(st, world_x, world_y, world_z, size, color)
			
			# Side faces (only where there's a height difference)
			# Check neighbor to the right (+X)
			if x < grid_size - 2:
				var neighbor_height := _get_height(heightmap, grid_size, x + 1, z)
				var neighbor_y := neighbor_height * height_scale * terrain_scale
				if world_y > neighbor_y:
					_add_side_face_x_pos(st, world_x, world_y, world_z, size, neighbor_y, color)
				elif world_y < neighbor_y:
					var neighbor_color := _height_to_color(neighbor_y)
					_add_side_face_x_neg(st, world_x + size, neighbor_y, world_z, size, world_y, neighbor_color)
			
			# Check neighbor to the front (+Z)
			if z < grid_size - 2:
				var neighbor_height := _get_height(heightmap, grid_size, x, z + 1)
				var neighbor_y := neighbor_height * height_scale * terrain_scale
				if world_y > neighbor_y:
					_add_side_face_z_pos(st, world_x, world_y, world_z, size, neighbor_y, color)
				elif world_y < neighbor_y:
					var neighbor_color := _height_to_color(neighbor_y)
					_add_side_face_z_neg(st, world_x, neighbor_y, world_z + size, size, world_y, neighbor_color)
			
			# Check neighbor behind (-X) - edge case for first column
			if x == 0:
				_add_side_face_x_neg(st, world_x, world_y, world_z, size, world_y - 5.0, color)
			
			# Check neighbor left (-Z) - edge case for first row
			if z == 0:
				_add_side_face_z_neg(st, world_x, world_y, world_z, size, world_y - 5.0, color)
	
	st.generate_normals()
	st.generate_tangents()
	
	return st.commit()


func _get_height(heightmap: PackedFloat32Array, grid_size: int, x: int, z: int) -> float:
	return heightmap[z * grid_size + x]


func _add_top_face(st: SurfaceTool, x: float, y: float, z: float, size: float, color: Color) -> void:
	st.set_color(color)
	st.set_uv(Vector2(0, 0))
	st.add_vertex(Vector3(x, y, z))
	st.set_uv(Vector2(1, 0))
	st.add_vertex(Vector3(x + size, y, z))
	st.set_uv(Vector2(1, 1))
	st.add_vertex(Vector3(x + size, y, z + size))
	
	st.set_color(color)
	st.set_uv(Vector2(0, 0))
	st.add_vertex(Vector3(x, y, z))
	st.set_uv(Vector2(1, 1))
	st.add_vertex(Vector3(x + size, y, z + size))
	st.set_uv(Vector2(0, 1))
	st.add_vertex(Vector3(x, y, z + size))


func _add_side_face_x_pos(st: SurfaceTool, x: float, y_top: float, z: float, size: float, y_bottom: float, color: Color) -> void:
	# Side face on +X edge (facing +X direction)
	var darker := color.darkened(0.2)
	st.set_color(darker)
	st.add_vertex(Vector3(x + size, y_top, z))
	st.add_vertex(Vector3(x + size, y_bottom, z))
	st.add_vertex(Vector3(x + size, y_bottom, z + size))
	
	st.set_color(darker)
	st.add_vertex(Vector3(x + size, y_top, z))
	st.add_vertex(Vector3(x + size, y_bottom, z + size))
	st.add_vertex(Vector3(x + size, y_top, z + size))


func _add_side_face_x_neg(st: SurfaceTool, x: float, y_top: float, z: float, size: float, y_bottom: float, color: Color) -> void:
	# Side face on -X edge (facing -X direction)
	var darker := color.darkened(0.2)
	st.set_color(darker)
	st.add_vertex(Vector3(x, y_top, z + size))
	st.add_vertex(Vector3(x, y_bottom, z + size))
	st.add_vertex(Vector3(x, y_bottom, z))
	
	st.set_color(darker)
	st.add_vertex(Vector3(x, y_top, z + size))
	st.add_vertex(Vector3(x, y_bottom, z))
	st.add_vertex(Vector3(x, y_top, z))


func _add_side_face_z_pos(st: SurfaceTool, x: float, y_top: float, z: float, size: float, y_bottom: float, color: Color) -> void:
	# Side face on +Z edge (facing +Z direction)
	var darker := color.darkened(0.3)
	st.set_color(darker)
	st.add_vertex(Vector3(x + size, y_top, z + size))
	st.add_vertex(Vector3(x + size, y_bottom, z + size))
	st.add_vertex(Vector3(x, y_bottom, z + size))
	
	st.set_color(darker)
	st.add_vertex(Vector3(x + size, y_top, z + size))
	st.add_vertex(Vector3(x, y_bottom, z + size))
	st.add_vertex(Vector3(x, y_top, z + size))


func _add_side_face_z_neg(st: SurfaceTool, x: float, y_top: float, z: float, size: float, y_bottom: float, color: Color) -> void:
	# Side face on -Z edge (facing -Z direction)
	var darker := color.darkened(0.3)
	st.set_color(darker)
	st.add_vertex(Vector3(x, y_top, z))
	st.add_vertex(Vector3(x, y_bottom, z))
	st.add_vertex(Vector3(x + size, y_bottom, z))
	
	st.set_color(darker)
	st.add_vertex(Vector3(x, y_top, z))
	st.add_vertex(Vector3(x + size, y_bottom, z))
	st.add_vertex(Vector3(x + size, y_top, z))


func _height_to_color(world_height: float) -> Color:
	"""Map world height to terrain color with transparency for underwater"""
	const WATER_LEVEL := 0.0
	const BEACH_HEIGHT := 2.0
	const GRASS_HEIGHT := 8.0
	const FOREST_HEIGHT := 18.0
	const ROCK_HEIGHT := 28.0
	const SNOW_HEIGHT := 38.0
	
	var color_underwater := Color(0.3, 0.5, 0.6, 0.0)
	var color_beach := Color(0.88, 0.82, 0.58, 1.0)
	var color_grass := Color(0.45, 0.72, 0.32, 1.0)
	var color_forest := Color(0.28, 0.52, 0.25, 1.0)
	var color_rock := Color(0.55, 0.52, 0.48, 1.0)
	var color_snow := Color(0.96, 0.97, 0.98, 1.0)
	
	if world_height < WATER_LEVEL:
		return color_underwater
	elif world_height < BEACH_HEIGHT:
		var t := _smoothstep(WATER_LEVEL, BEACH_HEIGHT, world_height)
		return color_underwater.lerp(color_beach, t)
	elif world_height < GRASS_HEIGHT:
		var t := _smoothstep(BEACH_HEIGHT, GRASS_HEIGHT, world_height)
		return color_beach.lerp(color_grass, t)
	elif world_height < FOREST_HEIGHT:
		var t := _smoothstep(GRASS_HEIGHT, FOREST_HEIGHT, world_height)
		return color_grass.lerp(color_forest, t)
	elif world_height < ROCK_HEIGHT:
		var t := _smoothstep(FOREST_HEIGHT, ROCK_HEIGHT, world_height)
		return color_forest.lerp(color_rock, t)
	else:
		var t := _smoothstep(ROCK_HEIGHT, SNOW_HEIGHT, world_height)
		return color_rock.lerp(color_snow, t)


func _smoothstep(edge0: float, edge1: float, x: float) -> float:
	var t := clampf((x - edge0) / (edge1 - edge0), 0.0, 1.0)
	return t * t * (3.0 - 2.0 * t)


func get_bounds(heightmap: PackedFloat32Array, grid_size: int) -> AABB:
	var min_h := 1e10
	var max_h := -1e10
	
	for h in heightmap:
		min_h = minf(min_h, h)
		max_h = maxf(max_h, h)
	
	var half_size := float(grid_size - 1) / 2.0 * terrain_scale
	var size := Vector3(
		half_size * 2.0,
		(max_h - min_h) * height_scale * terrain_scale,
		half_size * 2.0
	)
	var position := Vector3(-half_size, min_h * height_scale * terrain_scale, -half_size)
	
	return AABB(position, size)
