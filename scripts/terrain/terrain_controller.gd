class_name TerrainController
extends Node3D
## Main controller for terrain generation and display.

signal terrain_generated(generation_time_ms: float)

enum MeshStyle { SMOOTH, BLOCKS }

@export_group("Generation")
@export var auto_generate: bool = true
@export var mesh_style: MeshStyle = MeshStyle.BLOCKS:
	set(value):
		mesh_style = value
		if is_node_ready() and _generator:
			generate_terrain()

@export var terrain_seed: int = 12345:
	set(value):
		terrain_seed = value
		GameSettings.terrain_seed = value
		if is_node_ready() and _generator:
			generate_terrain()

@export_group("Terrain Dimensions")
@export_range(17, 513, 16) var grid_size: int = 129:  # Grid resolution (vertices per side)
	set(value):
		# Clamp to valid power-of-2 + 1 values
		var power := int(log(value - 1) / log(2))
		power = clampi(power, 4, 9)
		grid_size = (1 << power) + 1
		terrain_size = power
		GameSettings.terrain_size = power
		if is_node_ready() and _generator:
			generate_terrain()

@export_range(0.1, 5.0, 0.1) var terrain_scale: float = 1.5:  # Horizontal scale
	set(value):
		terrain_scale = value
		GameSettings.terrain_scale = value
		if is_node_ready() and _smooth_mesh_builder:
			_smooth_mesh_builder.terrain_scale = value
			_block_mesh_builder.terrain_scale = value
			generate_terrain()

@export_range(1.0, 100.0, 1.0) var height_scale: float = 25.0:  # Vertical scale
	set(value):
		height_scale = value
		GameSettings.height_scale = value
		if is_node_ready() and _smooth_mesh_builder:
			_smooth_mesh_builder.height_scale = value
			_block_mesh_builder.height_scale = value
			generate_terrain()

@export_group("Algorithm Settings")
@export_range(0.3, 0.9, 0.01) var roughness: float = 0.65:  # Midpoint displacement roughness
	set(value):
		roughness = value
		GameSettings.md_roughness = value
		if is_node_ready() and _generator:
			_generator.roughness = value
			generate_terrain()

@export_group("Island Mask")
@export_range(0.0, 1.0, 0.01) var island_inner_radius: float = 0.4:
	set(value):
		island_inner_radius = value
		GameSettings.island_inner_radius = value
		if is_node_ready() and _island_mask:
			_island_mask.inner_radius = value
			generate_terrain()

@export_range(0.0, 1.0, 0.01) var island_outer_radius: float = 0.85:
	set(value):
		island_outer_radius = value
		GameSettings.island_outer_radius = value
		if is_node_ready() and _island_mask:
			_island_mask.outer_radius = value
			generate_terrain()

@onready var mesh_instance: MeshInstance3D = $MeshInstance3D

var terrain_size: int = 7  # Internal power value for grid calculation
var _generator: BaseTerrainGenerator
var _island_mask: IslandMask
var _smooth_mesh_builder: TerrainMeshBuilder
var _block_mesh_builder: BlockMeshBuilder
var _current_heightmap: PackedFloat32Array


func _ready() -> void:
	_setup_components()
	
	# Sync with GameSettings after components are set up
	terrain_seed = GameSettings.terrain_seed
	terrain_size = GameSettings.terrain_size
	grid_size = GameSettings.get_grid_size()  # Sync grid_size from terrain_size
	terrain_scale = GameSettings.terrain_scale
	height_scale = GameSettings.height_scale
	roughness = GameSettings.md_roughness
	island_inner_radius = GameSettings.island_inner_radius
	island_outer_radius = GameSettings.island_outer_radius
	
	if auto_generate:
		generate_terrain()


func _setup_components() -> void:
	_generator = MidpointDisplacement.new()
	_generator.roughness = GameSettings.md_roughness
	
	_island_mask = IslandMask.new()
	_island_mask.inner_radius = GameSettings.island_inner_radius
	_island_mask.outer_radius = GameSettings.island_outer_radius
	
	_smooth_mesh_builder = TerrainMeshBuilder.new()
	_smooth_mesh_builder.height_scale = GameSettings.height_scale
	_smooth_mesh_builder.terrain_scale = GameSettings.terrain_scale
	
	_block_mesh_builder = BlockMeshBuilder.new()
	_block_mesh_builder.height_scale = GameSettings.height_scale
	_block_mesh_builder.terrain_scale = GameSettings.terrain_scale
	
	# Create MeshInstance if not present
	if not mesh_instance:
		mesh_instance = MeshInstance3D.new()
		mesh_instance.name = "MeshInstance3D"
		add_child(mesh_instance)


func generate_terrain() -> void:
	var current_grid_size := GameSettings.get_grid_size()
	var seed_value := GameSettings.terrain_seed
	
	# Update generator settings
	if _generator is MidpointDisplacement:
		_generator.roughness = GameSettings.md_roughness
	
	# Generate base heightmap
	var start_time := Time.get_ticks_msec()
	var raw_heightmap := _generator.generate(current_grid_size, seed_value)
	
	# Apply island mask ONLY to Midpoint Displacement
	# Perlin noise should remain unmasked for full terrain variation
	if _generator is MidpointDisplacement:
		_current_heightmap = _island_mask.apply(raw_heightmap, current_grid_size)
	else:
		_current_heightmap = raw_heightmap
	
	# Choose mesh builder based on style and build mesh
	var mesh: ArrayMesh
	if mesh_style == MeshStyle.SMOOTH:
		_smooth_mesh_builder.height_scale = GameSettings.height_scale
		_smooth_mesh_builder.terrain_scale = GameSettings.terrain_scale
		mesh = _smooth_mesh_builder.build_mesh(_current_heightmap, current_grid_size)
	else:
		_block_mesh_builder.height_scale = GameSettings.height_scale
		_block_mesh_builder.terrain_scale = GameSettings.terrain_scale
		mesh = _block_mesh_builder.build_mesh(_current_heightmap, current_grid_size)
	
	mesh_instance.mesh = mesh
	
	var elapsed := Time.get_ticks_msec() - start_time
	terrain_generated.emit(float(elapsed))
	
	var style_name := "Smooth" if mesh_style == MeshStyle.SMOOTH else "Blocks"
	print("Terrain generated: %s (%s), %dx%d grid, %.1fms" % [
		_generator.get_algorithm_name(),
		style_name,
		current_grid_size, current_grid_size,
		elapsed
	])


func set_algorithm(algo: GameSettings.Algorithm) -> void:
	match algo:
		GameSettings.Algorithm.MIDPOINT_DISPLACEMENT:
			_generator = MidpointDisplacement.new()
			_generator.roughness = GameSettings.md_roughness
		GameSettings.Algorithm.PERLIN_NOISE:
			_generator = PerlinNoise.new()
			# Use default Perlin settings for now
	
	GameSettings.current_algorithm = algo


func regenerate_with_new_seed() -> void:
	GameSettings.randomize_seed()
	generate_terrain()


func get_heightmap() -> PackedFloat32Array:
	return _current_heightmap


func get_height_at(world_x: float, world_z: float) -> float:
	"""Get interpolated height at world coordinates."""
	var current_grid_size := GameSettings.get_grid_size()
	
	# Convert world coords to grid coords
	var gx := (world_x / GameSettings.terrain_scale) + (current_grid_size - 1) / 2.0
	var gz := (world_z / GameSettings.terrain_scale) + (current_grid_size - 1) / 2.0
	
	# Clamp to valid range
	gx = clampf(gx, 0.0, float(current_grid_size - 1))
	gz = clampf(gz, 0.0, float(current_grid_size - 1))
	
	# Bilinear interpolation
	var x0 := int(gx)
	var z0 := int(gz)
	var x1 := mini(x0 + 1, current_grid_size - 1)
	var z1 := mini(z0 + 1, current_grid_size - 1)
	
	var fx := gx - float(x0)
	var fz := gz - float(z0)
	
	var h00 := _current_heightmap[z0 * current_grid_size + x0]
	var h10 := _current_heightmap[z0 * current_grid_size + x1]
	var h01 := _current_heightmap[z1 * current_grid_size + x0]
	var h11 := _current_heightmap[z1 * current_grid_size + x1]
	
	var h0 := lerpf(h00, h10, fx)
	var h1 := lerpf(h01, h11, fx)
	
	return lerpf(h0, h1, fz) * GameSettings.height_scale * GameSettings.terrain_scale


func flatten_terrain() -> void:
	"""Generate a completely flat terrain at water level."""
	var current_grid_size := GameSettings.get_grid_size()
	var flat_height := 0.05  # Slightly above water (0.0)
	
	# Create flat heightmap
	_current_heightmap.resize(current_grid_size * current_grid_size)
	_current_heightmap.fill(flat_height)
	
	# Build mesh based on style
	var mesh: ArrayMesh
	if mesh_style == MeshStyle.SMOOTH:
		_smooth_mesh_builder.height_scale = GameSettings.height_scale
		_smooth_mesh_builder.terrain_scale = GameSettings.terrain_scale
		mesh = _smooth_mesh_builder.build_mesh(_current_heightmap, current_grid_size)
	else:
		_block_mesh_builder.height_scale = GameSettings.height_scale
		_block_mesh_builder.terrain_scale = GameSettings.terrain_scale
		mesh = _block_mesh_builder.build_mesh(_current_heightmap, current_grid_size)
	
	mesh_instance.mesh = mesh
	
	mesh_instance.mesh = mesh
	
	print("Terrain flattened: %dx%d grid" % [current_grid_size, current_grid_size])
