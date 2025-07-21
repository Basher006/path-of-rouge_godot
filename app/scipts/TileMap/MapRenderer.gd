# res://app/scipts/TileMap/MapRenderer.gd
# Renders tiles on TileMap layers.
class_name MapRenderer
extends Node

@export var floor_layer: TileMapLayer
@export var walls_layer: TileMapLayer
@export var floor_atlas_id: int = 0
@export var walls_atlas_id: int = 0

var floor_cell_size: int = 16
var wall_cell_size: int = 8


# Sets floor tile at position.
func set_floor_tile(pos: Vector2i, index: Vector2i) -> void:
	floor_layer.set_cell(pos, floor_atlas_id, index)


# Sets wall tile at position.
func set_wall_tile(pos: Vector2i, index: Vector2i) -> void:
	walls_layer.set_cell(pos, walls_atlas_id, index)


# Clears all walls.
func clear_walls() -> void:
	walls_layer.clear()


# Clears all floor tiles.
func clear_floor() -> void:
	floor_layer.clear()
