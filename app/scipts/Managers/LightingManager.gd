# res://app/scipts/Managers/LightingManager.gd
# Manages lighting and field of view (FOV).
extends Node

const LIGHT_OFFSET_FLOOR: int = 2
const LIGHT_OFFSET_WALLS: int = 4

enum LightLevel { FULL = 1, MED = 2, LOW = 3, DARK = 4, DARKNESS_EXPLORED = 5 }

# lit_tiles: { pos: Vector2i => { source_id: int => light_level: LightLevel } }
var lit_tiles: Dictionary = {}
var light_sources: Dictionary = {}  # { id: int => LightSourceComponent }

var _light_id: int = 0


# Updates light for a source at new position.
func update_light(light_source: LightSourceComponent, new_pos: Vector2i) -> void:
	var tiles_to_redraw: Dictionary = {}
	var new_fov: Dictionary = _compute_fov(new_pos, light_source)
	
	_update_old_tiles(light_source, new_fov, tiles_to_redraw)
	_update_new_tiles(light_source, new_fov, tiles_to_redraw)
	light_source.last_calculated_fov = new_fov
	
	_update_wall_lights(tiles_to_redraw)
	GridManager.update_tiles(tiles_to_redraw)


# Updates tiles no longer in FOV.
func _update_old_tiles(light_source: LightSourceComponent, new_fov: Dictionary, tiles_to_redraw: Dictionary) -> void:
	for pos in light_source.last_calculated_fov:
		if not new_fov.has(pos):
			if lit_tiles.has(pos):
				var contributors: Dictionary = lit_tiles[pos]
				contributors.erase(light_source.id)
				var max_light: LightLevel = _get_max_light(contributors)
				_set_tile_light(pos, max_light, tiles_to_redraw)


# Updates tiles now in FOV.
func _update_new_tiles(light_source: LightSourceComponent, new_fov: Dictionary, tiles_to_redraw: Dictionary) -> void:
	for pos in new_fov:
		var tile: MyTileData = GridManager.get_tile(pos)
		if not tile or not tile.has_property("floor_tile_texture"):
			continue
		
		var old_light: LightLevel = tile.get_property("floor_light_level", LightLevel.DARK)
		var contributors: Dictionary = lit_tiles.get(pos, {})
		contributors[light_source.id] = new_fov[pos]
		lit_tiles[pos] = contributors
		
		var new_light: LightLevel = _get_max_light(contributors)
		if new_light != old_light:
			_set_tile_light(pos, new_light, tiles_to_redraw)
			GridManager.set_floor_as_explored(pos)


# Returns max light level from contributors (min enum value is brighter).
func _get_max_light(contributors: Dictionary) -> LightLevel:
	var max_light: LightLevel = LightLevel.DARK
	for light_value in contributors.values():
		if light_value < max_light:
			max_light = light_value
	return max_light


# Sets tile light level and marks for redraw.
func _set_tile_light(pos: Vector2i, light: LightLevel, tiles_to_redraw: Dictionary) -> void:
	var tile: MyTileData = GridManager.get_tile(pos)
	tile.set_property("floor_light_level", light)
	if light < LightLevel.DARK and not tile.get_property("floor_explored", false):
		tile.set_property("floor_explored", true)
	tiles_to_redraw[pos] = true


# Updates wall lights around changed floor tiles.
func _update_wall_lights(tiles_to_redraw: Dictionary) -> void:
	var changed_positions = tiles_to_redraw.keys().duplicate()
	for pos in changed_positions:
		for x in range(-1, 2):
			for y in range(-1, 2):
				var wall_pos: Vector2i = pos + Vector2i(x, y)
				if _update_single_wall_light(wall_pos):
					tiles_to_redraw[wall_pos] = true


# Computes FOV as { pos: Vector2i => LightLevel }.
func _compute_fov(pos: Vector2i, light_source: LightSourceComponent) -> Dictionary:
	var affected_cells: Dictionary = MRPAS.compute_fov(GridManager, pos, light_source.radius)
	for cell_pos in affected_cells:
		affected_cells[cell_pos] = distance_to_light_level(affected_cells[cell_pos], light_source.radius, light_source.levels)
	return affected_cells


# Updates light for a single wall position; returns true if changed.
func _update_single_wall_light(pos: Vector2i) -> bool:
	if not GridManager.is_valid_pos(pos):
		return false
	var tile: MyTileData = GridManager.get_tile(pos)
	if not tile:
		return false
	
	var old_light: Array = tile.get_property("walls_light_level", [])
	var new_light: Array
	if tile.has_property("floor_tile_texture"):
		new_light = _calc_floor_light_levels(tile)
	else:
		var textures: Array = tile.get_property("wall_tile_texture", [])
		if DualGridx8Mapper.is_close_corner_tiles(textures):
			new_light = _calc_close_corner_wall_light_levels(pos)
		else:
			new_light = _calc_standard_wall_light_levels(pos)
	
	if new_light != old_light:
		tile.set_property("walls_light_level", new_light)
		GridManager.set_wall_as_explored(pos, new_light)
		return true
	return false


# Calculates uniform light levels for floor.
func _calc_floor_light_levels(tile: MyTileData) -> Array:
	var light: LightLevel = tile.get_property("floor_light_level", LightLevel.DARK)
	return [light, light, light, light]


# Calculates wall light levels for close corners.
func _calc_close_corner_wall_light_levels(pos: Vector2i) -> Array:
	var left: LightLevel = GridManager.get_floor_tile_light(pos + Vector2i(1, 0))
	var top: LightLevel = GridManager.get_floor_tile_light(pos + Vector2i(0, 1))
	var right: LightLevel = GridManager.get_floor_tile_light(pos + Vector2i(-1, 0))
	var down: LightLevel = GridManager.get_floor_tile_light(pos + Vector2i(0, -1))
	
	var top_left: LightLevel = GridManager.get_floor_tile_light(pos + Vector2i(1, 1))
	var top_right: LightLevel = GridManager.get_floor_tile_light(pos + Vector2i(-1, 1))
	var down_left: LightLevel = GridManager.get_floor_tile_light(pos + Vector2i(1, -1))
	var down_right: LightLevel = GridManager.get_floor_tile_light(pos + Vector2i(-1, -1))
	
	return [
		min(top, left, top_left),
		min(top, right, top_right),
		min(down, left, down_left),
		min(down, right, down_right)
	]


# Calculates standard wall light levels.
func _calc_standard_wall_light_levels(pos: Vector2i) -> Array:
	var left: LightLevel = GridManager.get_floor_tile_light(pos + Vector2i(1, 0))
	var top: LightLevel = GridManager.get_floor_tile_light(pos + Vector2i(0, 1))
	var right: LightLevel = GridManager.get_floor_tile_light(pos + Vector2i(-1, 0))
	var down: LightLevel = GridManager.get_floor_tile_light(pos + Vector2i(0, -1))
	
	return [
		min(top, left),
		min(top, right),
		min(down, left),
		min(down, right)
	]


# Registers a new light source.
func register_light(light: LightSourceComponent) -> void:
	_light_id += 1
	light.id = _light_id
	light_sources[light.id] = light


# Unregisters a light source.
func unregister_light(id: int) -> void:
	if light_sources.has(id):
		light_sources.erase(id)


# Returns wall texture index with light offset.
func get_walls_texture_index_with_light_offset(texture_index: Vector2i, light: int, explored: bool) -> Vector2i:
	if light < LightLevel.DARK:
		return _get_walls_light_offset(texture_index, light)
	if light == LightLevel.DARK and explored:
		return _get_walls_light_offset(texture_index, LightLevel.DARKNESS_EXPLORED)
	return _get_walls_light_offset(texture_index, LightLevel.DARK)


# Returns floor texture index with light offset.
func get_floor_texture_index_with_light_offset(texture_index: Vector2i, light: int, explored: bool) -> Vector2i:
	if light < LightLevel.DARK:
		return _get_floor_light_offset(texture_index, light)
	if light == LightLevel.DARK and explored:
		return _get_floor_light_offset(texture_index, LightLevel.DARKNESS_EXPLORED)
	return _get_floor_light_offset(texture_index, LightLevel.DARK)


# Converts distance to LightLevel.
func distance_to_light_level(distance: float, max_distance: int, levels: Array) -> LightLevel:
	var full_threshold: float = max_distance * levels[0]
	var med_threshold: float = max_distance * levels[1]
	var low_threshold: float = max_distance
	
	if distance <= full_threshold:
		return LightLevel.FULL
	if distance <= med_threshold:
		return LightLevel.MED
	if distance <= low_threshold:
		return LightLevel.LOW
	return LightLevel.DARK


func _get_walls_light_offset(pos_in_atlas: Vector2i, light: int) -> Vector2i:
	return pos_in_atlas + Vector2i(light * LIGHT_OFFSET_WALLS, 0)


func _get_floor_light_offset(pos_in_atlas: Vector2i, light: int) -> Vector2i:
	return pos_in_atlas + Vector2i(light * LIGHT_OFFSET_FLOOR, 0)
