extends Node2D


@export var _map_render: MapRenderer 


func _ready() -> void:
	print("init world!")
	init()


func init() -> void:
	var level = MapGenerator.load_from_image("res://app/assets/test_level.png")
	print("level loaded form image")
	GridManager.map_renderer = _map_render
	GridManager.level = level
	GridManager.map_level()
	GridManager.draw_full_level()
