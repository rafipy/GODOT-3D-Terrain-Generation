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

@export_range(0.1, 5.0, 0.1) var terrain_scale: float = 1.5:
	set(value):
		terrain_scale = value
		GameSettings.terrain_scale = value
		if is_node_ready() and _smooth_mesh_builder:
			_smooth_mesh_builder.terrain_scale = value
			_block_mesh_builder.terrain_scale = value
			generate_terrain()

@export_range(1.0, 100.0, 1.0) var height_scale: float = 25.0:
	set(value):
		height_scale = value
		GameSettings.height_scale = value
		if is_node_ready() and _smooth_mesh_builder:
			_smooth_mesh_builder.height_scale = value
			_block_mesh_builder.height_scale = value
			generate_terrain()

@export_group("Algorithm Settings")
@export_range(0.3, 0.9, 0.01) var roughness: float = 0.65:
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

var _generator: BaseTerrainGenerator
var _island_mask: IslandMask
var _smooth_mesh_builder: TerrainMeshBuilder
var _block_mesh_builder: BlockMeshBuilder
var _current_heightmap: PackedFloat32Array
var _pending_heightmap: PackedFloat32Array 
var _pending_grid_size: int = 0  


func _ready() -> void:
	_setup_components()
	add_to_group("terrain")
	GameSettings.settings_changed.connect(_on_settings_changed)
	
	if auto_generate:
		generate_terrain()


func force_generate():
	"""Force regeneration and immediate mesh update (called by Refresh button)"""
	generate_terrain(true)


func _on_settings_changed() -> void:
	set_algorithm()
	
	# Always generate data in background, but only update mesh if auto_refresh is on
	generate_terrain(GameSettings.auto_refresh)

	
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


func generate_terrain(update_mesh: bool = true) -> void:
	"""Generate terrain data. If update_mesh is false, only generate data without updating visual."""
	var current_grid_size := GameSettings.get_grid_size()
	var seed_value := GameSettings.terrain_seed
	
	# Update generator settings
	if _generator is MidpointDisplacement:
		_generator.roughness = GameSettings.md_roughness
	
	# Generate base heightmap
	var start_time := Time.get_ticks_msec()
	var raw_heightmap := _generator.generate(current_grid_size, seed_value)
	
	# Apply island mask ONLY to Midpoint Displacement
	var generated_heightmap: PackedFloat32Array
	if _generator is MidpointDisplacement:
		generated_heightmap = _island_mask.apply(raw_heightmap, current_grid_size)
	else:
		generated_heightmap = raw_heightmap
	
	var elapsed := Time.get_ticks_msec() - start_time
	
	if update_mesh:
		# Apply immediately to mesh
		_current_heightmap = generated_heightmap
		_apply_heightmap_to_mesh(current_grid_size, elapsed)
	else:
		# Store for later application
		_pending_heightmap = generated_heightmap
		_pending_grid_size = current_grid_size
		print("Terrain generated in background: %s, %dx%d grid, %.1fms (not applied to mesh)" % [
			_generator.get_algorithm_name(),
			current_grid_size, current_grid_size,
			elapsed
		])


func apply_pending_terrain() -> void:
	"""Apply the pending terrain data to the mesh (called when auto_refresh is turned on or Refresh is pressed)"""
	if _pending_heightmap.size() > 0 and _pending_grid_size > 0:
		_current_heightmap = _pending_heightmap
		_apply_heightmap_to_mesh(_pending_grid_size, 0.0)
		# Clear pending data
		_pending_heightmap = PackedFloat32Array()
		_pending_grid_size = 0
		print("Applied pending terrain to mesh")


func _apply_heightmap_to_mesh(grid_size: int, generation_time: float) -> void:
	"""Build and apply mesh from current heightmap"""
	# Choose mesh builder based on style and build mesh
	var mesh: ArrayMesh
	if mesh_style == MeshStyle.SMOOTH:
		_smooth_mesh_builder.height_scale = GameSettings.height_scale
		_smooth_mesh_builder.terrain_scale = GameSettings.terrain_scale
		mesh = _smooth_mesh_builder.build_mesh(_current_heightmap, grid_size)
	else:
		_block_mesh_builder.height_scale = GameSettings.height_scale
		_block_mesh_builder.terrain_scale = GameSettings.terrain_scale
		mesh = _block_mesh_builder.build_mesh(_current_heightmap, grid_size)
	
	mesh_instance.mesh = mesh
	
	if generation_time > 0:
		terrain_generated.emit(generation_time)
	
	var style_name := "Smooth" if mesh_style == MeshStyle.SMOOTH else "Blocks"
	print("Terrain applied to mesh: %s (%s), %dx%d grid" % [
		_generator.get_algorithm_name(),
		style_name,
		grid_size, grid_size
	])


func set_algorithm() -> void:
	match GameSettings.current_algorithm:
		GameSettings.Algorithm.MIDPOINT_DISPLACEMENT:
			_generator = MidpointDisplacement.new()
			_generator.roughness = GameSettings.md_roughness
		GameSettings.Algorithm.PERLIN_NOISE:
			_generator = PerlinNoise.new()


func regenerate_with_new_seed() -> void:
	GameSettings.randomize_seed()
	generate_terrain(GameSettings.auto_refresh)


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
	
	print("Terrain flattened: %dx%d grid" % [current_grid_size, current_grid_size])
