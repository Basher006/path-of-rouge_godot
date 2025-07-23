# res://app/scripts/managers/G.gd
# Точка входа. Центральный класс.
extends  Node


const TILE_SIZE: int = 16


func world_to_grid(pos: Vector2i) -> Vector2i:
	return Vector2i(pos.x / TILE_SIZE, pos.y / TILE_SIZE)

func grid_to_world(pos: Vector2i) -> Vector2i:
	return Vector2i(pos.x * TILE_SIZE, pos.y * TILE_SIZE)
