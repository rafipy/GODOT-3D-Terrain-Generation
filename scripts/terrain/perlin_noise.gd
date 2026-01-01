class_name PerlinNoise
extends BaseTerrainGenerator
## Perlin noise terrain generator with full height range.
## Creates varied terrain from underwater valleys to mountain peaks.

# Noise settings
var octaves: int = 6
var frequency: float = 0.02
var persistence: float = 0.5
var lacunarity: float = 2.0

var _noise: FastNoiseLite


func _init() -> void:
	super._init()
	_noise = FastNoiseLite.new()
	# Use standard FBM for full [-1, 1] range (RIDGED only gives [0, 1])
	_noise.noise_type = FastNoiseLite.TYPE_PERLIN
	_noise.fractal_type = FastNoiseLite.FRACTAL_FBM


func _generate_impl() -> void:
	# Update noise parameters
	_noise.seed = _rng.seed
	_noise.fractal_octaves = octaves
	_noise.frequency = frequency
	_noise.fractal_lacunarity = lacunarity
	_noise.fractal_gain = persistence
	
	var min_raw := 1e10
	var max_raw := -1e10
	
	# First pass: collect raw noise values to find actual range
	var raw_values: Array[float] = []
	raw_values.resize(_grid_size * _grid_size)
	
	for y in range(_grid_size):
		for x in range(_grid_size):
			var noise_value := _noise.get_noise_2d(float(x), float(y))
			raw_values[y * _grid_size + x] = noise_value
			min_raw = minf(min_raw, noise_value)
			max_raw = maxf(max_raw, noise_value)
	
	print("Raw noise range: [%.3f, %.3f]" % [min_raw, max_raw])
	
	# Second pass: normalize to full [0, 1] range, then shift for underwater
	var min_height := 1e10
	var max_height := -1e10
	
	for y in range(_grid_size):
		for x in range(_grid_size):
			var raw := raw_values[y * _grid_size + x]
			
			# Normalize raw noise to [0, 1] based on actual range
			var normalized := (raw - min_raw) / (max_raw - min_raw)
			
			# Shift down so ~20% is underwater (below 0)
			# Map [0, 1] to [-0.2, 1.0]
			var height := normalized * 1.2 - 0.2
			
			min_height = minf(min_height, height)
			max_height = maxf(max_height, height)
			
			set_height(x, y, height)
	
	print("Perlin height range: [%.3f, %.3f] (world Y: [%.1f, %.1f])" % [
		min_height, max_height,
		min_height * 25.0 * 1.5, max_height * 25.0 * 1.5
	])


func get_algorithm_name() -> String:
	return "Perlin Noise"
