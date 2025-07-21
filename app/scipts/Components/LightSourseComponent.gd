# res://app/scipts/Components/LightSourseComponent.gd
# Component that adds a light source to the level.
class_name LightSourceComponent
extends Node2D

@export var radius: int = 8
@export var energy: float = 1.0
@export var levels: Array[float] = [0.4, 0.7]

var last_grid_pos: Vector2i = Vector2i(-1, -1)
var id: int = -1
var last_calculated_fov: Dictionary = {}


func _enter_tree() -> void:
	LightingManager.register_light(self)


func _exit_tree() -> void:
	LightingManager.unregister_light(id)


# Updates light at current position.
func update() -> void:
	LightingManager.update_light(self, last_grid_pos)


# Moves light to new position and updates.
func move_light(new_pos: Vector2i) -> void:
	LightingManager.update_light(self, new_pos)
	last_grid_pos = new_pos
