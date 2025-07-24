# res://app/scripts/managers/TurnManager.gd
# Manages turn-based game flow.
extends Node

signal turn_changed(new_state)

enum TurnState { PLAYER_TURN, ENVIRONMENT_TURN, ENEMY_TURN }

var current_state: TurnState = TurnState.PLAYER_TURN
var turn_delay: float = 0.05


# Initializes and emits initial turn state.
func _ready() -> void:
	turn_changed.emit(current_state)


# Processes a full turn cycle.
func process_turn() -> void:
	_set_state(TurnState.ENVIRONMENT_TURN)
	await _handle_environment_turn()
	
	_set_state(TurnState.ENEMY_TURN)
	await _handle_enemy_turn()
	
	_set_state(TurnState.PLAYER_TURN)


# Checks if it's the player's turn.
func is_player_turn() -> bool:
	return current_state == TurnState.PLAYER_TURN


# Sets and emits new turn state.
func _set_state(new_state: TurnState) -> void:
	current_state = new_state
	turn_changed.emit(current_state)


# Handles environment turn phase.
func _handle_environment_turn() -> void:
	# TODO: Add environment logic (traps, etc.).
	await get_tree().create_timer(turn_delay).timeout


# Handles enemy turn phase.
func _handle_enemy_turn() -> void:
	# TODO: Add enemy logic (call perform_turn on each).
	await get_tree().create_timer(turn_delay).timeout
