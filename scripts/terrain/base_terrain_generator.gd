class_name BaseTerrainGenerator
extends RefCounted
## Abstract base class for terrain generation algorithms.
## Subclasses implement specific generation methods.

signal generation_started
signal generation_completed(heightmap: PackedFloat32Array, time_ms: float)

var _rng: RandomNumberGenerator
var _grid_size: int
var _heightmap: PackedFloat32Array


func _init() -> void:
	_rng = RandomNumberGenerator.new()


func generate(grid_size: int, seed_value: int) -> PackedFloat32Array:
	"""Generate heightmap. Override in subclass."""
	generation_started.emit()
	
	var start_time := Time.get_ticks_msec()
	
	_grid_size = grid_size
	_rng.seed = seed_value
	_heightmap = PackedFloat32Array()
	_heightmap.resize(grid_size * grid_size)
	
	_generate_impl()
	
	var elapsed := Time.get_ticks_msec() - start_time
	generation_completed.emit(_heightmap, float(elapsed))
	
	return _heightmap


func _generate_impl() -> void:
	"""Override this method in subclasses."""
	push_error("_generate_impl must be overridden")


func get_height(x: int, y: int) -> float:
	if x < 0 or x >= _grid_size or y < 0 or y >= _grid_size:
		return 0.0
	return _heightmap[y * _grid_size + x]


func set_height(x: int, y: int, value: float) -> void:
	if x < 0 or x >= _grid_size or y < 0 or y >= _grid_size:
		return
	_heightmap[y * _grid_size + x] = value


func get_algorithm_name() -> String:
	return "BaseTerrainGenerator"
