# res://utils/DualGridx8Mapper.gd
# Utility for auto-tiling walls using dual grid method for 8x8 sub-tiles.
extends Node

const EMPTY_TILE: Vector2i = Vector2i(2, 4)

const NEIGHBORS_TO_ATLAS_COORD: Dictionary = {
	0: [Vector2i(2, 4), Vector2i(2, 4), Vector2i(2, 4), Vector2i(2, 4)],  # All empty
	1: [Vector2i(1, 1), Vector2i(2, 4), Vector2i(1, 4), Vector2i(2, 4)],  # Outer top-left corner
	2: [Vector2i(2, 4), Vector2i(0, 1), Vector2i(2, 4), Vector2i(0, 4)],  # Outer top-right corner
	3: [Vector2i(3, 3), Vector2i(2, 3), Vector2i(1, 4), Vector2i(0, 4)],  # Top edge
	4: [Vector2i(2, 4), Vector2i(2, 4), Vector2i(1, 0), Vector2i(2, 4)],  # Outer bottom-left corner
	5: [Vector2i(3, 1), Vector2i(2, 4), Vector2i(3, 0), Vector2i(2, 4)],  # Left edge
	6: [Vector2i(2, 4), Vector2i(0, 1), Vector2i(1, 0), Vector2i(0, 4)],  # Bottom-left and top-right corners
	7: [Vector2i(0, 2), Vector2i(2, 3), Vector2i(3, 0), Vector2i(0, 4)],  # Inner top-left corner
	8: [Vector2i(2, 4), Vector2i(2, 4), Vector2i(2, 4), Vector2i(0, 0)],  # Outer bottom-right corner
	9: [Vector2i(1, 1), Vector2i(2, 4), Vector2i(1, 4), Vector2i(0, 0)],  # Top-left and bottom-right corners
	10: [Vector2i(2, 4), Vector2i(2, 1), Vector2i(2, 4), Vector2i(2, 0)], # Right edge
	11: [Vector2i(3, 3), Vector2i(1, 2), Vector2i(1, 4), Vector2i(2, 0)], # Inner top-right corner
	12: [Vector2i(2, 4), Vector2i(2, 4), Vector2i(3, 2), Vector2i(2, 2)], # Bottom edge
	13: [Vector2i(3, 1), Vector2i(2, 4), Vector2i(0, 3), Vector2i(2, 2)], # Inner bottom-left corner
	14: [Vector2i(2, 4), Vector2i(2, 1), Vector2i(3, 2), Vector2i(1, 3)], # Inner bottom-right corner
	15: [Vector2i(3, 4), Vector2i(3, 4), Vector2i(3, 4), Vector2i(3, 4)],  # All corners
}


# Returns atlas coordinates for a 2x2 neighborhood of walls.
# Order: top_left, top_right, bottom_left, bottom_right (true = wall).
func get_walls_atlas_coord(top_left: bool, top_right: bool, bottom_left: bool, bottom_right: bool) -> Array:
	var key: int = 0
	if top_left: key |= 1
	if top_right: key |= 2
	if bottom_left: key |= 4
	if bottom_right: key |= 8
	return NEIGHBORS_TO_ATLAS_COORD.get(key, [EMPTY_TILE, EMPTY_TILE, EMPTY_TILE, EMPTY_TILE])


# Array version of get_walls_atlas_coord.
func get_walls_atlas_coord_array(matrix_2x2: Array) -> Array:
	return get_walls_atlas_coord(matrix_2x2[0], matrix_2x2[1], matrix_2x2[2], matrix_2x2[3])


# Returns floor atlas coord in checkerboard pattern with light level offset.
func get_floor_atlas_coord(pos: Vector2i, atlas_index: int = 0) -> Vector2i:
	var tile_index: int = (pos.x + pos.y) % 2  # 0 or 1 for checkerboard
	var offset: int = atlas_index * 2
	return Vector2i(tile_index + offset, 0)


# Checks if any texture in array is a close corner tile.
func is_close_corner_tiles(textures: Array) -> bool:
	for texture in textures:
		if is_close_corner_tile(texture):
			return true
	return false


# Checks if a single texture is a close corner tile.
func is_close_corner_tile(texture_index: Vector2i) -> bool:
	return texture_index in [Vector2i(0, 2), Vector2i(1, 2), Vector2i(0, 3), Vector2i(1, 3)]
