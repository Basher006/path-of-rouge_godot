# res://app/scipts/Managers/MapGenerator.gd
# Generates game levels.
extends Node

const DEFAULT_LIGHT_LEVEL: LightingManager.LightLevel = LightingManager.LightLevel.DARK
const DEFAULT_EXPLORED: bool = false


# Loads level from image (colors map to tile types).
func load_from_image(path: String) -> LevelData:
	var image: Image = Image.new()
	if image.load(path) != OK:
		return null
	
	var img_width: int = image.get_width()
	var img_height: int = image.get_height()
	var level: LevelData = LevelData.new()
	level.initialize(img_width, img_height)
	
	var color_to_type: Dictionary = {
		Color(0, 0, 0): GridManager.TileType.WALL,
		Color(1, 1, 1): GridManager.TileType.EMPTY,
		Color(1, 0, 0): GridManager.TileType.INTERACTIVE
	}
	
	for y in range(img_height):
		for x in range(img_width):
			var color: Color = image.get_pixel(x, y)
			var type: GridManager.TileType = GridManager.TileType.EMPTY
			for map_color in color_to_type:
				if color.is_equal_approx(map_color):
					type = color_to_type[map_color]
					break
			
			var tile: MyTileData = level.grid[y][x]
			tile.set_property("type", type)
			tile.set_property("walls_light_level", [DEFAULT_LIGHT_LEVEL, DEFAULT_LIGHT_LEVEL, DEFAULT_LIGHT_LEVEL, DEFAULT_LIGHT_LEVEL])
			tile.set_property("walls_explored", [DEFAULT_EXPLORED, DEFAULT_EXPLORED, DEFAULT_EXPLORED, DEFAULT_EXPLORED])
			
			match type:
				GridManager.TileType.EMPTY, GridManager.TileType.INTERACTIVE:
					tile.is_walkable = true
					tile.is_transparent = true
					tile.set_property("floor_light_level", DEFAULT_LIGHT_LEVEL)
					tile.set_property("floor_explored", DEFAULT_EXPLORED)
				GridManager.TileType.WALL:
					tile.is_walkable = false
					tile.is_transparent = false
	
	return level
