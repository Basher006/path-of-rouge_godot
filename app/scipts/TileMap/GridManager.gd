# res://app/TileMap/GridManager.gd
# Manages tile data access for the level.
extends Node

enum TileType { EMPTY, WALL, INTERACTIVE }

var level: LevelData
var map_renderer: MapRenderer


# Returns tile data at position or null if invalid.
func get_tile(pos: Vector2i) -> MyTileData:
	if not is_valid_pos(pos):
		return null
	return level.grid[pos.y][pos.x]


# Returns floor light level at position.
func get_floor_tile_light(pos: Vector2i) -> LightingManager.LightLevel:
	var tile: MyTileData = get_tile(pos)
	if tile and tile.has_property("floor_light_level"):
		return tile.get_property("floor_light_level", LightingManager.LightLevel.DARK)
	return LightingManager.LightLevel.DARK


# Checks if position is walkable.
func is_walkable(pos: Vector2i) -> bool:
	var tile: MyTileData = get_tile(pos)
	return tile and tile.is_walkable


# Checks if position is valid within level bounds.
func is_valid_pos(pos: Vector2i) -> bool:
	return level and pos.x >= 0 and pos.x < level.width and pos.y >= 0 and pos.y < level.height


# Checks if position is transparent to light.
func is_transparent(pos: Vector2i) -> bool:
	var tile: MyTileData = get_tile(pos)
	return tile and tile.is_transparent


# Maps the entire level (sets floor/wall textures).
func map_level() -> void:
	if not level:
		return
	
	for y in range(level.height - 1):
		for x in range(level.width - 1):
			var pos: Vector2i = Vector2i(x, y)
			var tile: MyTileData = get_tile(pos)
			if not tile:
				continue
			
			var tile_type: TileType = tile.get_property("type", TileType.EMPTY)
			if tile_type == TileType.EMPTY:
				tile.set_property("floor_tile_texture", DualGridx8Mapper.get_floor_atlas_coord(pos))
			
			var wall_matrix: Array = _get_walls_matrix_2x2(pos)
			if wall_matrix.any(func(is_wall): return is_wall):
				var texture_indices: = DualGridx8Mapper.get_walls_atlas_coord_array(wall_matrix)
				_set_wall_tile_texture(pos + Vector2i(0, 0), texture_indices, 0)
				_set_wall_tile_texture(pos + Vector2i(1, 0), texture_indices, 1)
				_set_wall_tile_texture(pos + Vector2i(0, 1), texture_indices, 2)
				_set_wall_tile_texture(pos + Vector2i(1, 1), texture_indices, 3)


# Draws the entire level on the tilemap.
func draw_full_level() -> void:
	if not level:
		return
	
	map_renderer.clear_floor()
	map_renderer.clear_walls()
	
	for y in range(level.height - 1):
		for x in range(level.width - 1):
			var pos: Vector2i = Vector2i(x, y)
			if is_floor(pos):
				draw_floor(pos)
			draw_wall(pos)


# Updates and redraws specified tiles.
func update_tiles(tiles: Dictionary) -> void:
	for tile_pos in tiles.keys():
		if not is_valid_pos(tile_pos):
			continue
		var tile: MyTileData = get_tile(tile_pos)
		if not tile:
			continue
		if tile.has_property("floor_tile_texture"):
			draw_floor(tile_pos)
		if tile.has_property("wall_tile_texture"):
			draw_wall(tile_pos)


# Marks floor as explored.
func set_floor_as_explored(pos: Vector2i) -> void:
	var tile: MyTileData = get_tile(pos)
	if tile:
		tile.set_property("floor_explored", true)


# Marks walls as explored based on light levels.
func set_wall_as_explored(pos: Vector2i, light_levels: Array) -> void:
	var tile: MyTileData = get_tile(pos)
	if not tile:
		return
	var explored_flags: Array = tile.get_property("walls_explored", [false, false, false, false])
	var new_flags: Array = []
	for i in 4:
		new_flags.append(light_levels[i] < LightingManager.LightLevel.DARK or explored_flags[i])
	tile.set_property("walls_explored", new_flags)


# Draws floor tile with light and exploration.
func draw_floor(pos: Vector2i) -> void:
	var tile: MyTileData = get_tile(pos)
	if not tile:
		return
	var texture_index: Vector2i = tile.get_property("floor_tile_texture", Vector2i.ZERO)
	var light_level: int = tile.get_property("floor_light_level", LightingManager.LightLevel.DARK)
	var explored: bool = tile.get_property("floor_explored", false)
	var final_index: Vector2i = LightingManager.get_floor_texture_index_with_light_offset(texture_index, light_level, explored)
	map_renderer.set_floor_tile(pos, final_index)


# Draws wall sub-tiles with light and exploration.
func draw_wall(pos: Vector2i) -> void:
	var tile: MyTileData = get_tile(pos)
	if not tile or not tile.has_property("wall_tile_texture"):
		return
	
	var texture_indices: Array = tile.get_property("wall_tile_texture", [])
	var light_levels: Array = tile.get_property("walls_light_level", [])
	var explored_flags: Array = tile.get_property("walls_explored", [false, false, false, false])
	
	var walls_cell_pos: Vector2i = pos_to_walls_cell_pos(pos)
	_draw_wall_subtile(walls_cell_pos + Vector2i(1, 1), texture_indices, light_levels, explored_flags, 0)  # Top-left
	_draw_wall_subtile(walls_cell_pos + Vector2i(0, 1), texture_indices, light_levels, explored_flags, 1)  # Top-right
	_draw_wall_subtile(walls_cell_pos + Vector2i(1, 0), texture_indices, light_levels, explored_flags, 2)  # Bottom-left
	_draw_wall_subtile(walls_cell_pos + Vector2i(0, 0), texture_indices, light_levels, explored_flags, 3)  # Bottom-right


# Draws a single wall sub-tile.
func _draw_wall_subtile(cell_pos: Vector2i, texture_indices: Array, light_levels: Array, explored_flags: Array, index: int) -> void:
	var light: int = light_levels[index] if index < light_levels.size() else LightingManager.LightLevel.DARK
	var explored: bool = explored_flags[index] if index < explored_flags.size() else false
	var final_index: Vector2i = LightingManager.get_walls_texture_index_with_light_offset(texture_indices[index], light, explored)
	map_renderer.set_wall_tile(cell_pos, final_index)


# Converts grid pos to walls cell pos.
func pos_to_walls_cell_pos(pos: Vector2i) -> Vector2i:
	var world_pos: Vector2i = cell_pos_to_world_pos(pos)
	return world_pos / map_renderer.wall_cell_size


# Sets wall texture property for a sub-tile.
func _set_wall_tile_texture(pos: Vector2i, values: Array, index: int) -> void:
	var tile: MyTileData = get_tile(pos)
	if not tile:
		return
	var textures: Array = tile.get_property("wall_tile_texture", [DualGridx8Mapper.EMPTY_TILE, DualGridx8Mapper.EMPTY_TILE, DualGridx8Mapper.EMPTY_TILE, DualGridx8Mapper.EMPTY_TILE])
	textures[index] = values[index]
	tile.set_property("wall_tile_texture", textures)


# Converts cell pos to world pos.
func cell_pos_to_world_pos(pos: Vector2i) -> Vector2i:
	return pos * map_renderer.floor_cell_size


# Returns 2x2 wall matrix at position.
func _get_walls_matrix_2x2(pos: Vector2i) -> Array:
	return [
		is_wall(pos),
		is_wall(pos + Vector2i(1, 0)),
		is_wall(pos + Vector2i(0, 1)),
		is_wall(pos + Vector2i(1, 1))
	]


# Checks if position is a wall.
func is_wall(pos: Vector2i) -> bool:
	var tile: MyTileData = get_tile(pos)
	return tile and tile.get_property("type") == TileType.WALL


# Checks if position is floor.
func is_floor(pos: Vector2i) -> bool:
	var tile: MyTileData = get_tile(pos)
	return tile and tile.get_property("type") == TileType.EMPTY
