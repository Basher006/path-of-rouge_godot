# res://app/TileMap/MyTileData.gd
# Stores data for a single tile.
class_name MyTileData
extends RefCounted

var is_walkable: bool = true
var is_transparent: bool = true
var _data: Dictionary = {}


# Sets a property.
func set_property(key: StringName, value) -> void:
	_data[key] = value


# Gets a property or default.
func get_property(key: StringName, default = null):
	return _data.get(key, default)


# Checks if property exists.
func has_property(key: StringName) -> bool:
	return _data.has(key)
