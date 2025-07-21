# res://app/TileMap/MyTileData.gd
# Хранит все данные клетки.
class_name MyTileData
extends RefCounted

var is_walkable = true
var is_transparent = true
var _data: Dictionary = {}


# Создает запись.
func set_property(key: StringName, value):
	_data[key] = value

# Возвращает значение или default, если ключа нет.
func get_property(key: StringName, default_value = null):
	return _data.get(key, default_value)

# Проверка наличия свойства.
func has_property(key: StringName) -> bool:
	return _data.has(key)
