class_name MidpointDisplacement
extends BaseTerrainGenerator
## Diamond-Square algorithm for terrain generation.
## Time: O(n^2), Space: O(n^2) where n = grid_size

var roughness: float = 0.5  # Height reduction factor per iteration


func _generate_impl() -> void:
	# Initialize corners with random values
	var max_idx := _grid_size - 1
	set_height(0, 0, _rng.randf_range(-1.0, 1.0))
	set_height(max_idx, 0, _rng.randf_range(-1.0, 1.0))
	set_height(0, max_idx, _rng.randf_range(-1.0, 1.0))
	set_height(max_idx, max_idx, _rng.randf_range(-1.0, 1.0))
	
	# Diamond-square iterations
	var step := max_idx
	var scale := 1.0
	
	while step > 1:
		@warning_ignore("integer_division")
		var half := step / 2
		
		# Diamond step
		_diamond_step(step, half, scale)
		
		# Square step
		_square_step(step, half, scale)
		
		step = half
		scale *= roughness


func _diamond_step(step: int, half: int, scale: float) -> void:
	"""Calculate center points of each square."""
	var y := half
	while y < _grid_size:
		var x := half
		while x < _grid_size:
			var avg := _average_corners(x, y, half)
			var offset := _rng.randf_range(-scale, scale)
			set_height(x, y, avg + offset)
			x += step
		y += step


func _square_step(step: int, half: int, scale: float) -> void:
	"""Calculate edge midpoints of each diamond."""
	var y := 0
	while y < _grid_size:
		var x := (y + half) % step
		while x < _grid_size:
			var avg := _average_diamond(x, y, half)
			var offset := _rng.randf_range(-scale, scale)
			set_height(x, y, avg + offset)
			x += step
		y += half


func _average_corners(x: int, y: int, half: int) -> float:
	"""Average of four corner points for diamond step."""
	var sum := 0.0
	sum += get_height(x - half, y - half)
	sum += get_height(x + half, y - half)
	sum += get_height(x - half, y + half)
	sum += get_height(x + half, y + half)
	return sum / 4.0


func _average_diamond(x: int, y: int, half: int) -> float:
	"""Average of four diamond points for square step."""
	var sum := 0.0
	var count := 0
	
	# Top
	if y - half >= 0:
		sum += get_height(x, y - half)
		count += 1
	# Bottom
	if y + half < _grid_size:
		sum += get_height(x, y + half)
		count += 1
	# Left
	if x - half >= 0:
		sum += get_height(x - half, y)
		count += 1
	# Right
	if x + half < _grid_size:
		sum += get_height(x + half, y)
		count += 1
	
	return sum / float(count) if count > 0 else 0.0


func get_algorithm_name() -> String:
	return "Midpoint Displacement"
