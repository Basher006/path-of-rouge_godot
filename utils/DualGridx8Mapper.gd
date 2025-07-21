# res://utils/DualGridx8Mapper.gd
# Делает автотайлы по методу двойной сетки для 8x8 подтайлов.
extends Node


const empty_tile: Vector2i = Vector2i(2, 4)

const neighbours_to_atlas_coord: Dictionary = {
	0: [Vector2i(2, 4), Vector2i(2, 4), Vector2i(2, 4), Vector2i(2, 4)],  # (false, false, false, false) - пустой квадрат -> четрые пустых
	1: [Vector2i(1, 1), Vector2i(2, 4), Vector2i(1, 4), Vector2i(2, 4)],  # (true, false, false, false) - внешний верхний левый угол -> угол, 3 пустых
	2: [Vector2i(2, 4), Vector2i(0, 1), Vector2i(2, 4), Vector2i(0, 4)],  # (false, true, false, false) - Outer top-right corner
	3: [Vector2i(3, 3), Vector2i(2, 3), Vector2i(1, 4), Vector2i(0, 4)],  # (true, true, false, false) - Top edge
	4: [Vector2i(2, 4), Vector2i(2, 4), Vector2i(1, 0), Vector2i(2, 4)],  # (false, false, true, false) - Outer bottom-left corner
	5: [Vector2i(3, 1), Vector2i(2, 4), Vector2i(3, 0), Vector2i(2, 4)],  # (true, false, true, false) - Left edge
	6: [Vector2i(2, 4), Vector2i(0, 1), Vector2i(1, 0), Vector2i(0, 4)],  # (false, true, true, false) - Bottom-left top-right corners
	7: [Vector2i(0, 2), Vector2i(2, 3), Vector2i(3, 0), Vector2i(0, 4)],  # (true, true, true, false) - Inner top-left corner
	8: [Vector2i(2, 4), Vector2i(2, 4), Vector2i(2, 4), Vector2i(0, 0)],  # (false, false, false, true) - Outer bottom-right corner
	9: [Vector2i(1, 1), Vector2i(2, 4), Vector2i(1, 4), Vector2i(0, 0)],  # (true, false, false, true) - Top-left down-right corners
	10: [Vector2i(2, 4), Vector2i(2, 1), Vector2i(2, 4), Vector2i(2, 0)], # (false, true, false, true) - Right edge
	11: [Vector2i(3, 3), Vector2i(1, 2), Vector2i(1, 4), Vector2i(2, 0)], # (true, true, false, true) - Inner top-right corner
	12: [Vector2i(2, 4), Vector2i(2, 4), Vector2i(3, 2), Vector2i(2, 2)], # (false, false, true, true) - Bottom edge
	13: [Vector2i(3, 1), Vector2i(2, 4), Vector2i(0, 3), Vector2i(2, 2)], # (true, false, true, true) - Inner bottom-left corner
	14: [Vector2i(2, 4), Vector2i(2, 1), Vector2i(3, 2), Vector2i(1, 3)], # (false, true, true, true) - Inner bottom-right corner
	15: [Vector2i(3, 4), Vector2i(3, 4), Vector2i(3, 4), Vector2i(3, 4)],  # (true, true, true, true) - All corners
}


# Метод для получения базовых координат атласа по 2x2 окрестности.
# Порядок: top_left, top_right, bottom_left, bottom_right (bool: true = стена).
func get_walls_atlas_coord(top_left: bool, top_right: bool, bottom_left: bool, bottom_right: bool) -> Array:
	var key: int = 0
	if top_left: key |= 1
	if top_right: key |= 2
	if bottom_left: key |= 4
	if bottom_right: key |= 8
	var res = neighbours_to_atlas_coord.get(key, [empty_tile, empty_tile, empty_tile, empty_tile])  # Дефолт: пустой тайл
	return res

func get_walls_atlas_coord_a(matrix2x2: Array[bool]) -> Array:
	return get_walls_atlas_coord(matrix2x2[0], matrix2x2[1], matrix2x2[2], matrix2x2[3])

# Метод для плиток пола в шахматном порядке.
# pos: позиция тайла в мире (Vector2i, например, (0,0), (1,0) и т.д.).
# atlas_index: int (0+). Возвращает Vector2i в атласе, с чередованием 0/1 + сдвиг по X (light_level * 2).
# Предполагает, что базовые плитки в (0,0) и (1,0), следующие уровни в (2,0)/(3,0) и т.д.
func get_floor_atlas_coord(pos: Vector2i, atlas_index: int = 0) -> Vector2i:
	var tile_index = (pos.x + pos.y) % 2  # 0 или 1 для шахматного паттерна
	var offset = atlas_index * 2
	return Vector2i(tile_index + offset, 0)

func is_close_corner_tiles(textures: Array) -> bool:
	return is_close_corner_tile(textures[0]) or is_close_corner_tile(textures[1]) or is_close_corner_tile(textures[2]) or is_close_corner_tile(textures[3]);

func is_close_corner_tile(texture_index: Vector2i) -> bool:
	if texture_index == Vector2i(0, 2) or texture_index == Vector2i(1, 2) or texture_index == Vector2i(0, 3) or texture_index == Vector2i(1, 3):
		return true
	
	return false
