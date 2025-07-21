# res://app/scipts/Managers/MapGenerator.gd
# Создает уровни игры.
extends  Node


const default_light_level = LightingManager.LightLevel.DARK
const default_explore_flag = false


func load_from_image(path: String) -> LevelData:
	var image = Image.new()
	if image.load(path) != OK :
		push_error("Failed to load image: " + path)
		return null
	
	var img_width = image.get_width()
	var img_height = image.get_height()
	var level = LevelData.new()
	level.init(img_width, img_height)
	
	var color_to_type: Dictionary = {
		Color(0, 0, 0): GridManager.TileType.WALL,     # Чёрный - стена
		Color(1, 1, 1): GridManager.TileType.EMPTY,    # Белый - пол
		Color(1, 0, 0): GridManager.TileType.INTERACTIVE  # Красный - дверь/сундук
	}
	
	for y in range(img_height):
		for x in range(img_width):
			var color = image.get_pixel(x, y)
			#var pos = Vector2i(x, y)
			# Используем is_equal_approx для tolerance (чтобы избежать проблем с артефактами в PNG)
			var type = GridManager.TileType.EMPTY  # Default
			for map_color in color_to_type:
				if color.is_equal_approx(map_color):
					type = color_to_type[map_color]
					break
			if type == GridManager.TileType.EMPTY:
				level.grid[y][x].is_walkable = true
				level.grid[y][x].is_transparent = true
				level.grid[y][x].set_property("type", GridManager.TileType.EMPTY)
				level.grid[y][x].set_property("floor_light_level", default_light_level)
				level.grid[y][x].set_property("floor_explored", default_explore_flag)
			elif type == GridManager.TileType.WALL:
				level.grid[y][x].is_walkable = false
				level.grid[y][x].is_transparent = false
				level.grid[y][x].set_property("type", GridManager.TileType.WALL)

			else:
				level.grid[y][x].set_property("type", GridManager.TileType.INTERACTIVE)
				level.grid[y][x].is_walkable = true
				level.grid[y][x].is_transparent = true
			
			level.grid[y][x].set_property("walls_light_level", 
				[default_light_level, 
				default_light_level, 
				default_light_level, 
				default_light_level])
			level.grid[y][x].set_property("walls_explored", [default_explore_flag, default_explore_flag, default_explore_flag, default_explore_flag])
			
	
	return level
