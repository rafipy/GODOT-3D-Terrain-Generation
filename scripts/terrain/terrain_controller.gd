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
		if !GameSettings.simulating:
			var msg = "%s, %dx%d grid, took %.0fms!" % [
				 		_generator.get_algorithm_name(),
						current_grid_size, current_grid_size, elapsed
						]
			show_popup(msg) 

var popup_window: Window = null
var active_tween: Tween = null

func show_popup(text: String, duration: float = 1, font_size: int = 12):
	# If a window already exists, clean up the old animation/content
	if is_instance_valid(popup_window):
		if active_tween:
			active_tween.kill() # Stop the old fade-out
		
		var label = popup_window.get_child(0) # Get the label
		label.text = text
		label.add_theme_font_size_override("font_size", font_size)
		start_fade_animation(label, duration)
		return

	#Setup the Window (Only if one doesn't exist)
	popup_window = Window.new()
	popup_window.transparent = true
	popup_window.borderless = true
	popup_window.unfocusable = true
	popup_window.mouse_passthrough = true
	popup_window.gui_embed_subwindows = true
	
	popup_window.size = Vector2i(800, 200) 
	get_tree().root.add_child(popup_window)
	
	
	var label := Label.new()
	label.name = "PopupLabel"
	label.text = text
	label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	label.add_theme_font_size_override("font_size", font_size)
	label.add_theme_color_override("font_color", Color.WHITE)
	label.add_theme_constant_override("outline_size", 8)
	label.add_theme_color_override("font_outline_color", Color.BLACK)
	
	label.set_anchors_and_offsets_preset(Control.PRESET_TOP_LEFT)
	label.grow_horizontal = Control.GROW_DIRECTION_BOTH
	
	label.modulate.a = 0.0
	popup_window.add_child(label)
	
	start_fade_animation(label, duration)

func start_fade_animation(label: Label, duration: float):
	# Create a new tween for this specific fade sequence
	active_tween = create_tween()
	

	active_tween.tween_property(label, "modulate:a", 1.0, 0.2)

	active_tween.tween_interval(duration)

	active_tween.tween_property(label, "modulate:a", 0.0, 0.4)
	
	active_tween.finished.connect(func():
		if is_instance_valid(popup_window):
			popup_window.queue_free()
			popup_window = null
	)
	
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

func calculate_fractal_dimension() -> float:
	var grid_size: int = _pending_grid_size if _pending_grid_size > 0 else GameSettings.get_grid_size()
	
	if grid_size < 8:
		return 2.0
	
	var heightmap := _pending_heightmap
	if heightmap.is_empty():
		print("Warning: No pending heightmap for fractal calculation")
		return 2.0
	
	var expected_size := grid_size * grid_size
	if heightmap.size() != expected_size:
		print("Error: Heightmap size mismatch. Expected: ", expected_size, " Got: ", heightmap.size())
		return 2.0
	
	return _calculate_fd_variogram(heightmap, grid_size)


func _calculate_fd_variogram(heightmap: PackedFloat32Array, grid_size: int) -> float:
	"""Calculate fractal dimension using variogram method - better for blocky terrain"""
	
	# Calculate variogram at different lag distances
	var max_lag := mini(grid_size / 4, 32)
	var lags := []
	var variances := []
	
	# Use powers of 2 for lag distances
	var lag := 1
	while lag <= max_lag:
		lags.append(lag)
		lag *= 2
	
	for lag_dist in lags:
		var sum_sq_diff := 0.0
		var count := 0
		
		# Sample in both X and Y directions
		# Horizontal differences
		for z in range(grid_size):
			for x in range(grid_size - lag_dist):
				var h1 := heightmap[z * grid_size + x]
				var h2 := heightmap[z * grid_size + x + lag_dist]
				sum_sq_diff += (h2 - h1) * (h2 - h1)
				count += 1
		
		# Vertical differences
		for z in range(grid_size - lag_dist):
			for x in range(grid_size):
				var h1 := heightmap[z * grid_size + x]
				var h2 := heightmap[(z + lag_dist) * grid_size + x]
				sum_sq_diff += (h2 - h1) * (h2 - h1)
				count += 1
		
		if count > 0:
			var variance := sum_sq_diff / float(count)
			variances.append(variance)
	
	if variances.size() < 3:
		return 2.0
	
	# Convert to log-log scale
	var log_lags: Array[float] = []
	var log_vars: Array[float] = []
	
	for i in range(lags.size()):
		if variances[i] > 0.0001:  # Avoid log(0)
			log_lags.append(log(float(lags[i])))
			log_vars.append(log(variances[i]))
	
	if log_lags.size() < 3:
		return 2.0
	
	# Linear regression
	var n := log_lags.size()
	var sum_x := 0.0
	var sum_y := 0.0
	var sum_xy := 0.0
	var sum_x2 := 0.0
	
	for i in range(n):
		sum_x += log_lags[i]
		sum_y += log_vars[i]
		sum_xy += log_lags[i] * log_vars[i]
		sum_x2 += log_lags[i] * log_lags[i]
	
	var denominator := n * sum_x2 - sum_x * sum_x
	if abs(denominator) < 0.001:
		return 2.0
	
	var slope := (n * sum_xy - sum_x * sum_y) / denominator
	
	# For variogram: Hurst exponent H = slope/2
	# Fractal dimension D = 3 - H for surfaces
	var hurst := slope / 2.0
	var fd := 3.0 - hurst
	
	return clampf(fd, 2.0, 3.0)
