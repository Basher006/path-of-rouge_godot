# res://app/scipts/Managers/LightingManager.gd
# Отвечает за освещение и область обзора
extends Node


const light_offset_floor: int = 2
const light_offset_walls: int = 4


# Ключ: Vector2i (позиция клетки)
# Значение: Dictionary { source_instance_id: light_level }
var lit_tiles: Dictionary = {}
var light_sourses: Dictionary = {}


var _light_id: int = 0


enum LightLevel {
	DEBUG = 0,
	FULL = 1,
	MED = 2,
	LOW = 3,
	DARK = 4,
	DARKNESS_EXPLORED = 5
}

func update_light(light_sourse: LightSourceComponent, new_pos: Vector2i) -> void:
# 1. Обновляем старые тайлы.
	var tiles_to_redraw: Dictionary = {}
	var new_fov = _compute_FOV(new_pos, light_sourse)
	for pos in light_sourse.last_calculated_fov:
		if not new_fov.has(pos):
			if lit_tiles.has(pos):
				var contributors: Dictionary = lit_tiles[pos]
				contributors.erase(light_sourse.id)
				
				var max_light = LightLevel.DARK as int
				for light_value in contributors.values():
					if light_value as int < max_light:
						max_light = light_value
				
				var tile = GridManager.get_tile(pos)
				if tile.has_property("floor_tile_texture"):
					# Обновляем свет в тайле.
					tile.set_property("floor_light_level", max_light as LightLevel)
					# Обновляем метку разведки.
					if max_light < LightLevel.DARK and not tile.get_property("floor_explored", false):
						tile.set_property("floor_explored", true)
					# Добавляем тайил в список тайлов которые нужно перерисовать. 
					tiles_to_redraw[pos] = true
	
	# 2. Обновляем новые тайлы.
	for pos in new_fov:
		var tile = GridManager.get_tile(pos)
		if tile.has_property("floor_tile_texture"):
			var old_final_light = tile.get_property("floor_light_level", LightLevel.DARK) 
			var contributors: Dictionary = lit_tiles.get(pos, {})
			contributors[light_sourse.id] = new_fov[pos]
			lit_tiles[pos] = contributors
			
			var new_final_light = LightLevel.DARK
			for light_value in contributors.values():
				if light_value as int < new_final_light as int:
					new_final_light = light_value
			
			if new_final_light != old_final_light:
				tile.set_property("floor_light_level", new_final_light)
				tiles_to_redraw[pos] = true
				GridManager.set_floor_as_explored(pos)
			
	light_sourse.last_calculated_fov = new_fov
	
	# Обновляем свет на стенах.
	var changed_floor_tiles = tiles_to_redraw.keys() # Создаем копию ключей, потому что мы можем добавлять новые элементы в tiles_to_redraw
	for floor_pos in changed_floor_tiles:
		for x in range(-1, 2):
			for y in range(-1, 2):
				#if x == 0 and y == 0:
					#continue # Пропускаем саму клетку
				var wall_candidate_pos = floor_pos + Vector2i(x, y)
				if _update_singe_wall_light(wall_candidate_pos):
					tiles_to_redraw[wall_candidate_pos] = true
	
	GridManager.update_tiles(tiles_to_redraw)

func _compute_FOV(pos: Vector2i, light_sourse: LightSourceComponent) -> Dictionary:
	# return Dict: pos: Vector2i, distance: float
	var affected_cells = MRPAS.compute_FOV(GridManager, pos, light_sourse.radius)
	# replase distance: float to LightLevel enum
	for cell_pos in affected_cells.keys():
		affected_cells[cell_pos] = distance_to_light_level(affected_cells[cell_pos], light_sourse.radius, light_sourse.levels)
	
	return affected_cells;

func _update_singe_wall_light(pos: Vector2i) -> bool:
	if GridManager.is_valid_pos(pos):
		var tile = GridManager.get_tile(pos)
		if tile != null:
			var new_wall_light = []
			var old_wall_light = tile.get_property("walls_light_level", [])
			if tile.has_property("floor_tile_texture"):
				new_wall_light = _calc_new_light_level_floor(tile)
			else:
				var tile_textures = tile.get_property("wall_tile_texture")
				if DualGridx8Mapper.is_close_corner_tiles(tile_textures):
					new_wall_light = _calc_new_light_level_walls_close_cornenr(pos)
				else:
					new_wall_light = _calc_new_light_level_walls(pos)
			if new_wall_light != old_wall_light:
				tile.set_property("walls_light_level", new_wall_light)
				GridManager.set_wall_as_explored(pos, new_wall_light)
				return true
	
	return true

func _calc_new_light_level_floor(tile: MyTileData) -> Array:
	var floor_tile_light = tile.get_property("floor_light_level", LightingManager.LightLevel.DARK)
	return [floor_tile_light, floor_tile_light, floor_tile_light, floor_tile_light]

func _calc_new_light_level_walls_close_cornenr(pos: Vector2i) -> Array:
	var left_light = GridManager.get_floor_tile_light(pos + Vector2i(1, 0))
	var top_light = GridManager.get_floor_tile_light(pos + Vector2i(0, 1))
	var right_light = GridManager.get_floor_tile_light(pos + Vector2i(-1, 0))
	var down_light = GridManager.get_floor_tile_light(pos + Vector2i(0, -1))
	
	var top_left_light = GridManager.get_floor_tile_light(pos + Vector2i(1, 1))
	var top_right_light = GridManager.get_floor_tile_light(pos + Vector2i(-1, 1))
	var down_left_light = GridManager.get_floor_tile_light(pos + Vector2i(1, -1))
	var down_right_light = GridManager.get_floor_tile_light(pos + Vector2i(-1, -1))
	
	var tl_light = min(top_light, left_light, top_left_light)
	var tr_light = min(top_light, right_light, top_right_light)
	var dl_light = min(down_light, left_light, down_left_light)
	var dr_light = min(down_light, right_light, down_right_light)
	
	return [tl_light, tr_light, dl_light, dr_light]

func _calc_new_light_level_walls(pos: Vector2i) -> Array:
	var left_light = GridManager.get_floor_tile_light(pos + Vector2i(1, 0))
	var top_light = GridManager.get_floor_tile_light(pos + Vector2i(0, 1))
	var right_light = GridManager.get_floor_tile_light(pos + Vector2i(-1, 0))
	var down_light = GridManager.get_floor_tile_light(pos + Vector2i(0, -1))
	
	var tl_light = min(top_light, left_light)
	var tr_light = min(top_light, right_light)
	var dl_light = min(down_light, left_light)
	var dr_light = min(down_light, right_light)
	
	return [tl_light, tr_light, dl_light, dr_light]

func register_light(light: LightSourceComponent) -> void:
	_light_id += 1
	light.id = _light_id
	light_sourses[light.id] = light

func unregister_light(id: int) -> void:
	if light_sourses.has(id):
		# очищаем клетки источника света преж чем удалить его (!)
		light_sourses.erase(id)

func get_walls_texture_index_with_light_offset(texture_index: Vector2i, light: int, explored: int) -> Vector2i:
	if light < LightLevel.DARK as int:
		return get_walls_light_offset(texture_index, light)
	else:
		if light == LightLevel.DARK as int and explored:
			return get_walls_light_offset(texture_index, LightLevel.DARKNESS_EXPLORED as int)
	
	return get_walls_light_offset(texture_index, LightLevel.DARK as int)

func get_floor_texture_index_with_light_offset(texture_index: Vector2i, light: int, explored: int) -> Vector2i:
	if light < LightLevel.DARK as int:
		return get_floor_light_offset(texture_index, light)
	else:
		if light == LightLevel.DARK as int and explored:
			return get_floor_light_offset(texture_index, LightLevel.DARKNESS_EXPLORED as int)
	
	return get_floor_light_offset(texture_index, LightLevel.DARK as int)

func distance_to_light_level(distance: float, max_distance: int, levels: Array[float]) -> LightLevel:
	var full_light_tr = max_distance * levels[0]
	var med_light_tr = max_distance * levels[1]
	var low_light_tr = max_distance
	
	if distance <=  full_light_tr:
		return LightLevel.FULL
	elif distance <= med_light_tr:
		return LightLevel.MED
	elif distance <= low_light_tr:
		return LightLevel.LOW
	
	return LightLevel.DARK

func get_walls_light_offset(pos_in_atlas: Vector2i, light: int) -> Vector2i:
	var offset = Vector2i(light * light_offset_walls, 0);
	return pos_in_atlas + offset

func get_floor_light_offset(pos_in_atlas: Vector2i, light: int) -> Vector2i:
	var offset = Vector2i(light * light_offset_floor, 0);
	return pos_in_atlas + offset
