class_name TerrainMeshBuilder
extends RefCounted
## Converts heightmap to 3D mesh with proper UVs and normals.

var height_scale: float = 25.0
var terrain_scale: float = 1.5


func build_mesh(heightmap: PackedFloat32Array, grid_size: int) -> ArrayMesh:
	var st := SurfaceTool.new()
	st.begin(Mesh.PRIMITIVE_TRIANGLES)
	
	var half_size := float(grid_size - 1) / 2.0
	
	# Generate vertices
	for y in range(grid_size):
		for x in range(grid_size):
			var height := heightmap[y * grid_size + x] * height_scale
			
			# Center the mesh at origin
			var vx := (float(x) - half_size) * terrain_scale
			var vy := height * terrain_scale
			var vz := (float(y) - half_size) * terrain_scale
			
			# UV coordinates
			var u := float(x) / float(grid_size - 1)
			var v := float(y) / float(grid_size - 1)
			
			# Color based on world height (vy is the actual Y position)
			var color := _height_to_color(vy)
			st.set_color(color)
			st.set_uv(Vector2(u, v))
			st.add_vertex(Vector3(vx, vy, vz))
	
	# Generate triangle indices
	for y in range(grid_size - 1):
		for x in range(grid_size - 1):
			var i := y * grid_size + x
			
			# First triangle (top-left)
			st.add_index(i)
			st.add_index(i + grid_size)
			st.add_index(i + 1)
			
			# Second triangle (bottom-right)
			st.add_index(i + 1)
			st.add_index(i + grid_size)
			st.add_index(i + grid_size + 1)
	
	st.generate_normals()
	st.generate_tangents()
	
	return st.commit()


func _height_to_color(world_height: float) -> Color:
	"""Map world height to terrain color with transparency for underwater portions"""
	# Height thresholds in world units
	const WATER_LEVEL := 0.0
	const BEACH_HEIGHT := 2.0
	const GRASS_HEIGHT := 8.0
	const FOREST_HEIGHT := 18.0
	const ROCK_HEIGHT := 28.0
	const SNOW_HEIGHT := 38.0
	
	# Vibrant colors for stylized look
	var color_underwater := Color(0.3, 0.5, 0.6, 0.0)  # Transparent underwater
	var color_beach := Color(0.88, 0.82, 0.58, 1.0)     # Sandy tan
	var color_grass := Color(0.45, 0.72, 0.32, 1.0)     # Bright green
	var color_forest := Color(0.28, 0.52, 0.25, 1.0)    # Dark green
	var color_rock := Color(0.55, 0.52, 0.48, 1.0)      # Gray-brown
	var color_snow := Color(0.96, 0.97, 0.98, 1.0)      # White
	
	if world_height < WATER_LEVEL:
		# Fully transparent for underwater terrain
		return color_underwater
	elif world_height < BEACH_HEIGHT:
		var t := smoothstep(WATER_LEVEL, BEACH_HEIGHT, world_height)
		return color_underwater.lerp(color_beach, t)
	elif world_height < GRASS_HEIGHT:
		var t := smoothstep(BEACH_HEIGHT, GRASS_HEIGHT, world_height)
		return color_beach.lerp(color_grass, t)
	elif world_height < FOREST_HEIGHT:
		var t := smoothstep(GRASS_HEIGHT, FOREST_HEIGHT, world_height)
		return color_grass.lerp(color_forest, t)
	elif world_height < ROCK_HEIGHT:
		var t := smoothstep(FOREST_HEIGHT, ROCK_HEIGHT, world_height)
		return color_forest.lerp(color_rock, t)
	else:
		var t := smoothstep(ROCK_HEIGHT, SNOW_HEIGHT, world_height)
		return color_rock.lerp(color_snow, t)


func smoothstep(edge0: float, edge1: float, x: float) -> float:
	var t := clampf((x - edge0) / (edge1 - edge0), 0.0, 1.0)
	return t * t * (3.0 - 2.0 * t)


func get_bounds(heightmap: PackedFloat32Array, grid_size: int) -> AABB:
	"""Calculate mesh bounding box."""
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
