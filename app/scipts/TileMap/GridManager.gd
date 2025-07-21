# res://app/TileMap/GridManager.gd
# Менеджер клеток таилмапы. Через него осуществляется доступ к данным уронвня
extends  Node


enum TileType{
	EMPTY,
	WALL,
	INTERACTIVE
}


var level: LevelData
var map_renderer: MapRenderer

func get_tile(pos: Vector2i) -> MyTileData:
	if not is_valid_pos(pos):
		push_warning("Invalid position: " + str(pos))
		return null
	return level.grid[pos.y][pos.x]

func get_floor_tile_light(pos: Vector2i) -> LightingManager.LightLevel:
	if is_valid_pos(pos):
		var tile = get_tile(pos)
		if tile != null:
			if tile.has_property("floor_light_level"):
				return tile.get_property("floor_light_level", LightingManager.LightLevel.DARK)
	
	return LightingManager.LightLevel.DARK

func is_walkable(pos: Vector2i) -> bool:
	var tile = get_tile(pos)
	if tile == null:
		return false
	return tile.is_walkable

func is_valid_pos(pos: Vector2i) -> bool:
	if level == null:
		return false
	
	return pos.x >= 0 and pos.x < level.width and pos.y >= 0 and pos.y < level.height

func is_transporent(pos: Vector2i) -> bool:
	if level == null:
		return false
	var tile = get_tile(pos)
	if tile == null:
		return false
	return tile.is_transparent

func map_level() -> void:
	if level == null:
		push_error("Cant mapping empty level!")
		return
	for y in range(level.height - 1):
		for x in range(level.width - 1):
			var pos = Vector2i(x, y)
			var tile = get_tile(pos)
			if tile != null:
				var tile_type = tile.get_property("type")
				if tile_type != null:
					if tile_type == TileType.EMPTY:
						tile.set_property("floor_tile_texture", DualGridx8Mapper.get_floor_atlas_coord(pos))
					var is_wall_matrix = _get_walls_matrix_2x2(pos) # HERE BIG THING WRONG (!!!)
					if is_wall_matrix[0] or is_wall_matrix[1] or is_wall_matrix[2] or is_wall_matrix[3]:
						var texture_indices = DualGridx8Mapper.get_walls_atlas_coord_a(is_wall_matrix)
						set_wall_tile_texture_property(pos + Vector2i(0, 0), texture_indices, 0)
						set_wall_tile_texture_property(pos + Vector2i(1, 0), texture_indices, 1)
						set_wall_tile_texture_property(pos + Vector2i(0, 1), texture_indices, 2)
						set_wall_tile_texture_property(pos + Vector2i(1, 1), texture_indices, 3)

func draw_full_level() -> void:
	if level == null:
		push_error("Cant draw empty level!")
		return
	map_renderer.clear_floor()
	map_renderer.clear_walls()
	for y in range(level.height - 1):
		for x in range(level.width - 1):
			var pos = Vector2i(x, y)
			var tile = get_tile(pos)
			if tile != null:
				if is_floor(pos):
					draw_floor(pos)
				draw_wall(pos)

func update_tiles(tiles: Dictionary) -> void:
	if not tiles.is_empty():
		for tile_pos in tiles.keys():
			if is_valid_pos(tile_pos):
				var tile = get_tile(tile_pos)
				if tile != null:
					if tile.has_property("floor_tile_texture"):
						draw_floor(tile_pos)
					if tile.has_property("wall_tile_texture"):
						draw_wall(tile_pos)

func set_floor_as_explored(pos: Vector2i) -> void:
	if is_valid_pos(pos):
		var tile = get_tile(pos)
		if tile != null:
			tile.set_property("floor_explored", true)

func set_wall_as_explored(pos: Vector2i, light_array: Array) -> void:
	if is_valid_pos(pos):
		var tile = get_tile(pos)
		if tile != null:
			var explored_flags = tile.get_property("walls_explored", [false, false, false, false])
			tile.set_property("walls_explored", [
				light_array[0] < LightingManager.LightLevel.DARK or explored_flags[0], 
				light_array[1] < LightingManager.LightLevel.DARK or explored_flags[1],
				light_array[2] < LightingManager.LightLevel.DARK or explored_flags[2], 
				light_array[3] < LightingManager.LightLevel.DARK or explored_flags[3]])

func draw_floor(pos: Vector2i) -> void:
	var tile = get_tile(pos)
	if tile != null:
		var floor_texture_index = tile.get_property("floor_tile_texture")
		var floor_light_level = tile.get_property("floor_light_level")
		var floor_explored = tile.get_property("floor_explored")
		if floor_texture_index != null and floor_light_level != null:
			var floor_light_texture_index = LightingManager.get_floor_texture_index_with_light_offset(floor_texture_index, floor_light_level, floor_explored)
			map_renderer.set_floor_tile(pos, floor_light_texture_index)

func draw_wall(pos: Vector2i) -> void:
	var tile = get_tile(pos)
	if tile != null:
		var wall_texture_indices = tile.get_property("wall_tile_texture")
		var wall_light_levels = tile.get_property("walls_light_level")
		var wall_explored = tile.get_property("walls_explored")
		if wall_texture_indices != null:
			var walls_cell_pos = pos_to_walls_cell_pos(pos)
			
			var lt_wall_cell_pos = walls_cell_pos + Vector2i(1, 1) # У меня нет идей почему оффсеты в обратном порядке.
			var rt_wall_cell_pos = walls_cell_pos + Vector2i(0, 1) # Но так оно заработало. 
			var lb_wall_cell_pos = walls_cell_pos + Vector2i(1, 0)
			var rb_wall_cell_pos = walls_cell_pos + Vector2i(0, 0)
			
			_draw_wall_subtile(lt_wall_cell_pos, wall_texture_indices, wall_light_levels, 0, wall_explored)
			_draw_wall_subtile(rt_wall_cell_pos, wall_texture_indices, wall_light_levels, 1, wall_explored)
			_draw_wall_subtile(lb_wall_cell_pos, wall_texture_indices, wall_light_levels, 2, wall_explored)
			_draw_wall_subtile(rb_wall_cell_pos, wall_texture_indices, wall_light_levels, 3, wall_explored)

func _draw_wall_subtile(walls_cell_pos: Vector2i, wall_texture_indices, wall_light_levels, index: int, explored) -> void:
	if wall_texture_indices != null:
		var light: int = LightingManager.LightLevel.DARK
		if wall_light_levels != null:
			light = wall_light_levels[index]
		var texture_index = LightingManager.get_walls_texture_index_with_light_offset(wall_texture_indices[index], light, explored[index])
		map_renderer.set_wall_tile(walls_cell_pos, texture_index)

func pos_to_walls_cell_pos(pos: Vector2i) -> Vector2i:
	var world_pos = cell_pos_to_world_pos(pos)
	return _world_to_walls_cell_pos(world_pos)

func set_wall_tile_texture_property(pos: Vector2i, values: Array, index: int) -> void:
	if is_valid_pos(pos):
		var tile = get_tile(pos)
		if tile != null:
			var texture = [DualGridx8Mapper.empty_tile ,DualGridx8Mapper.empty_tile ,DualGridx8Mapper.empty_tile , DualGridx8Mapper.empty_tile]
			if tile.has_property("wall_tile_texture"):
				texture = tile.get_property("wall_tile_texture", [])
				
			texture[index] = values[index]
			tile.set_property("wall_tile_texture", texture)

func cell_pos_to_world_pos(pos: Vector2i) -> Vector2i:
	return Vector2i(pos.x * map_renderer.floor_cell_size, pos.y * map_renderer.floor_cell_size)

func _world_to_walls_cell_pos(pos: Vector2i) -> Vector2i:
	return Vector2i(pos.x / map_renderer.wall_cell_size, pos.y / map_renderer.wall_cell_size)

func _get_walls_matrix_2x2(pos: Vector2i) -> Array[bool]:
	var lt_is_wall = is_wall(pos)
	var rt_is_wall = is_wall(pos + Vector2i(1, 0))
	var lb_is_wall = is_wall(pos + Vector2i(0, 1))
	var rb_is_wall = is_wall(pos + Vector2i(1, 1))
	
	return [lt_is_wall, rt_is_wall, lb_is_wall, rb_is_wall]

func is_wall(pos: Vector2i) -> bool:
	var tile = get_tile(pos)
	if tile != null:
		return tile.get_property("type") == TileType.WALL
	
	return false

func is_floor(pos: Vector2i) -> bool:
	var tile = get_tile(pos)
	if tile != null:
		return tile.get_property("type") == TileType.EMPTY
	
	return false
