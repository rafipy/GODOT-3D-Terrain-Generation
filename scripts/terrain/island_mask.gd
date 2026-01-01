class_name IslandMask
extends RefCounted
## Applies radial falloff to create island shape.
## Center is highest, edges sink below water level.

var inner_radius: float = 0.35  # Where falloff begins (0-1)
var outer_radius: float = 0.75  # Where height becomes negative (0-1)
var falloff_curve: float = 1.2  # Steepness of falloff
var noise_strength: float = 0.85  # How much noise affects terrain (0-1)
var base_height: float = 0.25  # Minimum height boost at center
var ocean_depth: float = -0.2  # How far below water the edges go


func apply(heightmap: PackedFloat32Array, grid_size: int) -> PackedFloat32Array:
	var result := PackedFloat32Array()
	result.resize(heightmap.size())
	
	var center := float(grid_size - 1) / 2.0
	var max_dist := center * 1.414  # Diagonal distance (sqrt(2))
	
	for y in range(grid_size):
		for x in range(grid_size):
			var idx := y * grid_size + x
			var dist := _distance_from_center(x, y, center) / max_dist
			
			var mask := _calculate_mask(dist)
			
			# Raw noise value from heightmap [-1, 1]
			var noise := heightmap[idx]
			
			# Scale noise by mask - full noise in center, none at edges
			var terrain_noise := noise * noise_strength * mask
			
			# Add base island elevation that fades to ocean at edges
			var island_base := _calculate_island_height(dist)
			
			# Combine: island base provides shape, noise adds variation
			result[idx] = island_base + terrain_noise
	
	return result


func _distance_from_center(x: int, y: int, center: float) -> float:
	var dx := float(x) - center
	var dy := float(y) - center
	return sqrt(dx * dx + dy * dy)


func _calculate_mask(normalized_distance: float) -> float:
	"""Returns 1.0 at center, 0.0 at edges."""
	if normalized_distance <= inner_radius:
		return 1.0
	elif normalized_distance >= outer_radius:
		return 0.0
	else:
		var t := (normalized_distance - inner_radius) / (outer_radius - inner_radius)
		t = t * t * (3.0 - 2.0 * t)  # smoothstep
		return 1.0 - t


func _calculate_island_height(normalized_distance: float) -> float:
	"""Returns height for island shape - high in center, below water at edges."""
	if normalized_distance <= inner_radius:
		# Flat-ish center plateau with slight dome
		var center_factor := 1.0 - (normalized_distance / inner_radius) * 0.2
		return base_height * center_factor
	elif normalized_distance >= outer_radius:
		# Below water at edges
		return ocean_depth
	else:
		# Smooth transition from plateau to ocean
		var t := (normalized_distance - inner_radius) / (outer_radius - inner_radius)
		t = t * t * (3.0 - 2.0 * t)  # smoothstep
		t = pow(t, falloff_curve)
		return lerpf(base_height, ocean_depth, t)


func get_mask_value(x: int, y: int, grid_size: int) -> float:
	"""Get mask value at specific coordinate."""
	var center := float(grid_size - 1) / 2.0
	var max_dist := center * 1.414
	var dist := _distance_from_center(x, y, center) / max_dist
	return _calculate_mask(dist)
