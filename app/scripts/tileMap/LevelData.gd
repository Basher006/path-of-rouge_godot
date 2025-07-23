# res://app/scripts/tileMap/LevelData.gd
# Stores level data and tile grid.
class_name LevelData
extends RefCounted

var grid: Array[Array] = []
var width: int = 0
var height: int = 0
var player_start_position: Vector2i = Vector2i.ZERO


# Initializes empty level of size width x height.
func initialize(w: int, h: int) -> void:
	width = w
	height = h
	grid.clear()
	for y in range(height):
		var row: Array[MyTileData] = []
		for x in range(width):
			row.append(MyTileData.new())
		grid.append(row)
