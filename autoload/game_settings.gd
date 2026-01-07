extends Node
## Global settings for terrain generation and comparison.
## Autoload singleton for consistent seed management across algorithms.

signal settings_changed
signal seed_changed(new_seed: int)

var auto_refresh: bool = false:
	set(value):
		auto_refresh = value

# Terrain generation seed - same for both algorithms
var terrain_seed: int = 12345:
	set(value):
		terrain_seed = value
		seed_changed.emit(value)

var terrain_power: int = 7:
	set(value):
		terrain_power = max(value, 1) # only prevent negatives
		settings_changed.emit()

var terrain_scale: float = 1.5:  # Larger terrain
	set(value):
		terrain_scale = clampf(value, 0.1, 5.0)
		settings_changed.emit()

# Height settings
var height_scale: float = 25.0  # Taller peaks
var water_level: float = 0.0

# Island mask settings
var island_inner_radius: float = 0.4  # Larger flat center
var island_outer_radius: float = 0.85  # Slower falloff to edges

# Algorithm selection
enum Algorithm { MIDPOINT_DISPLACEMENT, PERLIN_NOISE }
var current_algorithm: Algorithm = Algorithm.MIDPOINT_DISPLACEMENT

# Midpoint Displacement specific
var md_roughness: float = 0.65:  # Height reduction per iteration (higher = rougher)
	set(value):
		md_roughness = clampf(value, 0.3, 0.9)
		settings_changed.emit()

# Perlin Noise specific
var perlin_octaves: int = 6
var perlin_persistence: float = 0.5
var perlin_lacunarity: float = 2.0
var perlin_frequency: float = 0.02

var simulating: bool = false

# UI toggle states
var post_processing_enabled: bool = true:
	set(value):
		post_processing_enabled = value
		settings_changed.emit()

var camera_auto_rotate: bool = true:
	set(value):
		camera_auto_rotate = value
		settings_changed.emit()

# For shortcut customization - store Key enum value
var spin_toggle_key: Key = KEY_SPACE:
	set(value):
		spin_toggle_key = value
		settings_changed.emit()


func _ready() -> void:
	randomize()
	terrain_seed = randi()
	


func get_grid_size() -> int:
	return (1 << terrain_power) + 1


func create_rng() -> RandomNumberGenerator:
	var rng := RandomNumberGenerator.new()
	rng.seed = terrain_seed
	return rng


func randomize_seed() -> void:
	terrain_seed = randi()


func reset_to_defaults() -> void:
	terrain_power = 7
	terrain_scale = 1.5
	height_scale = 25.0
	md_roughness = 0.65
	island_inner_radius = 0.4
	island_outer_radius = 0.85
	current_algorithm = Algorithm.MIDPOINT_DISPLACEMENT
	settings_changed.emit()
