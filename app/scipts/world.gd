# res://app/scipts/world.gd
# World initializer: loads and renders the level.
class_name World
extends Node2D

@export var map_renderer: MapRenderer


func _ready() -> void:
	print("Initializing world!")
	_initialize_level()


# Initializes the level from image and renders it.
func _initialize_level() -> void:
	var level: LevelData = MapGenerator.load_from_image("res://app/assets/test_level.png")
	if not level:
		push_error("Failed to load level from image.")
		return
	
	print("Level loaded from image.")
	GridManager.map_renderer = map_renderer
	GridManager.level = level
	GridManager.map_level()
	GridManager.draw_full_level()
