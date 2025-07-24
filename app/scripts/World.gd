# res://app/scripts/World.gd
# Initializes and manages the game world.
class_name World
extends Node2D

@export var map_renderer: MapRenderer

@onready var turn_label: Label = $Canvas/DebugLabel

var player_actor: Actor


# Initializes the level and spawns the player.
func _ready() -> void:
	_initialize_level()
	TurnManager.turn_changed.connect(_on_turn_changed)


# Loads and renders the level.
func _initialize_level() -> void:
	var level: LevelData = MapGenerator.load_from_image("res://app/assets/test_level.png")
	if not level:
		push_error("Failed to load level from image.")
		return
	
	GridManager.map_renderer = map_renderer
	GridManager.level = level
	GridManager.map_level()
	GridManager.draw_full_level()
	
	_spawn_player()
	if player_actor:
		player_actor.update_fov()


# Spawns the player actor.
func _spawn_player() -> void:
	var start_pos: Vector2i = GridManager.get_player_start_position()
	player_actor = ActorFactory.create_actor("player", start_pos)
	
	if not player_actor:
		push_error("Failed to create player actor!")
		return
	
	add_child(player_actor)
	GridManager.add_actor(player_actor)
	player_actor.action_requested.connect(player_actor.perform_action)


# Handles turn state changes.
func _on_turn_changed(new_state: TurnManager.TurnState) -> void:
	match new_state:
		TurnManager.TurnState.PLAYER_TURN:
			turn_label.text = "Player's Turn"
		TurnManager.TurnState.ENVIRONMENT_TURN:
			turn_label.text = "Environment's Turn"
		TurnManager.TurnState.ENEMY_TURN:
			turn_label.text = "Enemies' Turn"
