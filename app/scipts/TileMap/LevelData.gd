# res://app/TileMap/LevelData.gd
# Хранит все данны об уровне и клетках.
class_name LevelData
extends RefCounted

var grid: Array = []
var width: int = 0
var height: int = 0


# Ициализирует пустой уровень размера W x H 
func init(w: int, h: int) -> void:
	width = w
	height = h
	grid.clear()
	for y in range(height):
		var row: Array = []
		for x in range(width):
			var tile = MyTileData.new()
			row.append(tile)
		grid.append(row)
