# res://app/scipts/Player.gd
# Player script for movement and light handling.
class_name Player
extends Node2D

const LIGHT_SOURCE_PREFAB: PackedScene = preload("res://app/scenes/light_source_component.tscn")

@onready var move_timer: Timer = $MoveTimer
@onready var sprite: Sprite2D = $PlayerSprite

@export var initial_delay: float = 0.2  # Delay before rapid movement starts (seconds)
@export var repeat_delay: float = 0.05  # Interval for repeated movement (seconds)

var current_direction: Vector2 = Vector2.ZERO
var light_component: LightSourceComponent

signal action_taken()  # Сигнал, который emit после любого действия (1 AP)

func init(pos: Vector2) -> void:
	# Move player to init position.
	position = G.grid_to_world(pos)
	
	# Add light source component.
	var light_instance: LightSourceComponent = LIGHT_SOURCE_PREFAB.instantiate()
	add_child(light_instance)
	light_component = light_instance
	light_component.radius = 12
	light_component.energy = 1.0
	light_component.last_grid_pos = get_grid_pos()
	light_component.update()
	
	# Setup timer.
	move_timer.one_shot = false
	move_timer.autostart = false
	move_timer.timeout.connect(_on_move_timer_timeout)
	
	# Debug: Move to starting position.

func _process(_delta: float) -> void:
	if TurnManager.current_state != TurnManager.TurnState.PLAYER_TURN:
		return
	
	var input_dir: Vector2 = get_input_direction()
	if input_dir != Vector2.ZERO:
		_move(input_dir)


# Gets current input direction (prioritizes right/left over down/up).
func get_input_direction() -> Vector2:
	if Input.is_action_pressed("Right"):
		return Vector2.RIGHT
	if Input.is_action_pressed("Left"):
		return Vector2.LEFT
	if Input.is_action_pressed("Down"):
		return Vector2.DOWN
	if Input.is_action_pressed("Up"):
		return Vector2.UP
	return Vector2.ZERO


func _on_move_timer_timeout() -> void:
	if current_direction != Vector2.ZERO and get_input_direction() == current_direction:
		# Repeat movement and restart timer with repeat delay.
		_move(current_direction)
		move_timer.start(repeat_delay)
	else:
		move_timer.stop()


# Moves player in direction if target is walkable.
func _move(dir: Vector2) -> void:
	# Flip sprite horizontally.
	if dir.x != 0:
		sprite.flip_h = dir.x < 0
	
	var current_grid: Vector2i = get_grid_pos()
	var target_grid: Vector2i = current_grid + Vector2i(dir)
	
	if GridManager.is_walkable(target_grid):
		position = G.grid_to_world(target_grid)
		light_component.move_light(target_grid)
		emit_signal("action_taken")


# Gets current grid position.
func get_grid_pos() -> Vector2i:
	return G.world_to_grid(position)
