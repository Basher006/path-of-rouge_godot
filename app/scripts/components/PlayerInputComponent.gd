# res://app/scripts/components/PlayerInputComponent.gd
# Handles player input for movement actions.
class_name PlayerInputComponent
extends ActorComponent


# Processes unhandled input events.
func _unhandled_input(event: InputEvent) -> void:
	if not TurnManager.is_player_turn():
		return
	
	var move_direction: Vector2i = _get_move_direction(event)
	if move_direction != Vector2i.ZERO:
		actor.action_requested.emit(move_direction)
		get_viewport().set_input_as_handled()


# Gets movement direction from input event.
func _get_move_direction(event: InputEvent) -> Vector2i:
	if event.is_action_pressed("Right"):
		return Vector2i.RIGHT
	if event.is_action_pressed("Left"):
		return Vector2i.LEFT
	if event.is_action_pressed("Down"):
		return Vector2i.DOWN
	if event.is_action_pressed("Up"):
		return Vector2i.UP
	return Vector2i.ZERO
