# res://utils/FOV algorithms/MRPAS.gd
# Mingos' Restrictive Precise Angle Shadowcasting (MRPAS) FOV algorithm.
# https://github.com/matt-kimball/godot-mrpas/tree/master
extends Node

enum MajorAxis { X_AXIS, Y_AXIS }


# Computes FOV as { pos: Vector2i => distance: float }.
func compute_fov(grid_provider, position: Vector2i, radius: int) -> Dictionary:
	var octants: Array[Dictionary] = [
		_compute_octant(grid_provider, MajorAxis.Y_AXIS, -1, -1, position, radius),
		_compute_octant(grid_provider, MajorAxis.Y_AXIS, -1, 1, position, radius),
		_compute_octant(grid_provider, MajorAxis.Y_AXIS, 1, -1, position, radius),
		_compute_octant(grid_provider, MajorAxis.Y_AXIS, 1, 1, position, radius),
		_compute_octant(grid_provider, MajorAxis.X_AXIS, -1, -1, position, radius),
		_compute_octant(grid_provider, MajorAxis.X_AXIS, -1, 1, position, radius),
		_compute_octant(grid_provider, MajorAxis.X_AXIS, 1, -1, position, radius),
		_compute_octant(grid_provider, MajorAxis.X_AXIS, 1, 1, position, radius)
	]
	return _combine_octants(octants)


# Combines octant results into one dictionary.
func _combine_octants(octants: Array[Dictionary]) -> Dictionary:
	var result: Dictionary = {}
	for octant in octants:
		result.merge(octant)
	return result


# Computes a single octant.
func _compute_octant(grid_provider, axis: MajorAxis, major_sign: int, minor_sign: int, position: Vector2i, max_distance: int) -> Dictionary:
	var occluders: Array[Vector2] = []
	var new_occluders: Array[Vector2] = []
	var result: Dictionary = {}
	
	for major in range(max_distance + 1):
		var any_transparent: bool = false
		var cur_pos: Vector2i = position + _octant_to_offset(axis, major_sign * major, 0)
		if not grid_provider.is_valid_pos(cur_pos):
			break
		
		var pos_delta: Vector2i = _octant_to_offset(axis, 0, minor_sign)
		var clamped_minor: int = _clamp_to_bounds(cur_pos, pos_delta, major + 1, grid_provider.level.width, grid_provider.level.height)
		var angle_half_step: float = 0.5 / (major + 1)
		
		for minor in range(clamped_minor):
			var angle: float = float(minor) / (major + 1)
			var transparent: bool = grid_provider.is_transparent(cur_pos)
			
			if not _is_occluded(occluders, angle, angle_half_step, transparent):
				result[cur_pos] = cur_pos.distance_to(position)
				if transparent:
					any_transparent = true
				else:
					new_occluders.append(Vector2(angle, angle + 2.0 * angle_half_step))
			
			cur_pos += pos_delta
		
		if not any_transparent:
			break
		
		occluders.append_array(new_occluders)
		new_occluders.clear()
	
	return result


# Converts octant coords to offset.
func _octant_to_offset(axis: MajorAxis, major: int, minor: int) -> Vector2i:
	return Vector2i(minor, major) if axis == MajorAxis.Y_AXIS else Vector2i(major, minor)


# Clamps iterations to map bounds.
func _clamp_to_bounds(pos: Vector2i, delta: Vector2i, iterations: int, size_x: int, size_y: int) -> int:
	if pos.x + delta.x * iterations < 0:
		iterations = int(-pos.x / float(delta.x)) + 1
	if pos.x + delta.x * iterations > size_x:
		iterations = int((size_x - pos.x) / float(delta.x))
	if pos.y + delta.y * iterations < 0:
		iterations = int(-pos.y / float(delta.y)) + 1
	if pos.y + delta.y * iterations > size_y:
		iterations = int((size_y - pos.y) / float(delta.y))
	return iterations


# Checks if angle is occluded.
func _is_occluded(occluders: Array[Vector2], angle: float, half_step: float, transparent: bool) -> bool:
	var begin: bool = _is_angle_occluded(occluders, angle)
	var mid: bool = _is_angle_occluded(occluders, angle + half_step)
	var end: bool = _is_angle_occluded(occluders, angle + 2.0 * half_step)
	
	if not transparent and (not begin or not mid or not end):
		return false
	if transparent and not mid and (not begin or not end):
		return false
	return true


# Checks if single angle is within any occluder.
func _is_angle_occluded(occluders: Array[Vector2], angle: float) -> bool:
	for occluder in occluders:
		if angle >= occluder.x and angle <= occluder.y:
			return true
	return false
