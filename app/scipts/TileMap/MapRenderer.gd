# res://app/scipts/TileMap/MapRenderer.gd
# Единственная задача этого класса, рисовать тайлы на тайлмапах
extends Node
class_name MapRenderer

@export var _floor: TileMapLayer
@export var _walls: TileMapLayer
@export var _floor_atlas_index: int = 0
@export var _walls_atlas_index: int = 0


var floor_cell_size: int = 16
var wall_cell_size: int = 8


func set_floor_tile(pos: Vector2i, index: Vector2i) -> void:
	_floor.set_cell(pos, _floor_atlas_index, index)

func set_wall_tile(pos: Vector2i, index: Vector2i) -> void:
	_walls.set_cell(pos, _walls_atlas_index, index)

func clear_walls() -> void:
	_walls.clear()

func clear_floor() -> void:
	_floor.clear()
