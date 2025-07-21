# res://utils/FOV algorithms/MRPAS.gd
# Алгоритм зоны видимости. 
# Mingos' Restrictive Precise Angle Shadowcasting (MRPAS)
# https://github.com/matt-kimball/godot-mrpas/tree/master
extends  Node


enum _MajorAxis { X_AXIS, Y_AXIS }

# Возвращает Dcitionary со всеми клетками которые попдают в область видимости, 
# в котором ключ это позиция клетки (Vector2i), и значение растояние (float).
# grid_provider это ваш менеджер тайлов или типо того, он должен сожержать методы:
# 	1. grid_provider.is_valid_pos(pos : Vector2i) -> bool (определяет валидность координат)
#	2. grid_provider.is_transporent(pos : Vector2i) -> bool (определяет проницаима ли клетка для света)
# А так же поля: grid_provider.level.width, grid_provider.level.height
func compute_FOV(grid_provider, position: Vector2i, radius: int) -> Dictionary:
	var r1 = _compute_octant(grid_provider, _MajorAxis.Y_AXIS, -1, -1, position, radius)
	var r2 = _compute_octant(grid_provider, _MajorAxis.Y_AXIS, -1, 1, position, radius)
	
	var r3 = _compute_octant(grid_provider, _MajorAxis.Y_AXIS, 1, -1, position, radius)
	var r4 = _compute_octant(grid_provider, _MajorAxis.Y_AXIS, 1, 1, position, radius)
	
	var r5 = _compute_octant(grid_provider, _MajorAxis.X_AXIS, -1, -1, position, radius)
	var r6 = _compute_octant(grid_provider, _MajorAxis.X_AXIS, -1, 1, position, radius)
	
	var r7 = _compute_octant(grid_provider, _MajorAxis.X_AXIS, 1, -1, position, radius)
	var r8 = _compute_octant(grid_provider, _MajorAxis.X_AXIS, 1, 1, position, radius)
	
	var result = _combine_octant_results([r1, r2, r3, r4, r5, r6, r7, r8])
	
	return result

func _combine_octant_results(results) -> Dictionary:
	var combined_result = {}
	for res in range(len(results)):
		for octan_res in results[res]:
			combined_result[octan_res] = results[res][octan_res]
	
	return combined_result


func _compute_octant(grid_provider, axis: int, major_sign: int, minor_sign: int, position: Vector2i, max_distance: int) -> Dictionary:
	var occluders = []
	var new_occluders = []
	var result: Dictionary = {}
	
	for major in range(max_distance + 1):
		var any_transparent = false
		
		var curPos = position + _octant_to_offset(axis, major_sign * major, 0)
		if (not grid_provider.is_valid_pos(curPos)): # (!) #  or curPos.distance_to(view_position) < max_distance
			break
		
		var pos_delta = _octant_to_offset(axis, 0, minor_sign)
		var clamped_minor = _clamp_to_map_bounds(curPos, pos_delta, major + 1, grid_provider.level.width, grid_provider.level.height)
		var angle_half_step = 0.5 / (major + 1) as float
		
		for minor in range(clamped_minor):
			var angle = minor as float / (major + 1) as float
			
			var transparent = grid_provider.is_transporent(curPos)
			#var transparent = true
			
			if not _is_occluded(occluders, angle, angle_half_step, transparent):
				result[curPos] = _calc_dist(curPos, position)
				if (transparent):
					any_transparent = true
				else:
					var occluder = Vector2(angle, angle + 2.0 * angle_half_step)
					new_occluders.push_back(occluder)
			
			curPos += pos_delta
			
		if not any_transparent:
			break
		
		occluders = occluders + new_occluders
		new_occluders.clear()
	
	return result

func _calc_dist(pos1: Vector2, pos2: Vector2) -> float:
	return pos1.distance_to(pos2)

func _octant_to_offset(axis: int, major: int, minor: int) -> Vector2i:
	if axis == _MajorAxis.Y_AXIS:
		return Vector2i(minor, major)
	else:
		return Vector2i(major, minor)

func _clamp_to_map_bounds(pos: Vector2, position_delta: Vector2, iterations: int, size_x: int, size_y: int) -> int:
	if pos.x + position_delta.x * iterations < 0:
		iterations = int(-pos.x / position_delta.x) + 1
	if pos.x + position_delta.x * iterations > size_x:
		iterations = int((size_x - pos.x) / position_delta.x)

	if pos.y + position_delta.y * iterations < 0:
		iterations = int(-pos.y / position_delta.y) + 1
	if pos.y + position_delta.y * iterations > size_y:
		iterations = int((size_y - pos.y) / position_delta.y)

	return iterations

func _is_occluded(occluders: Array, angle: float, angle_half_step: float, transparent: bool) -> bool:
	var begin = _is_angle_occluded(occluders, angle)
	var mid = _is_angle_occluded(occluders, angle + angle_half_step)
	var end = _is_angle_occluded(occluders, angle + 2.0 * angle_half_step)
	
	if not transparent and (not begin or not mid or not end):
		return false
	
	if transparent and not mid and (not begin or not end):
		return false
	
	return true

func _is_angle_occluded(occluders: Array, angle: float) -> bool:
	for occluder in occluders:
		if angle >= occluder.x and angle <= occluder.y:
			return true

	return false
