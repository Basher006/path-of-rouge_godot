# res://app/scripts/managers/TurnManager.gd
# Управляет пошаговой системой ходов в игре.
extends Node


signal turn_changed(new_state)


enum TurnState {
	PLAYER_TURN,
	ENVIRONMENT_TURN,
	ENEMY_TURN
}


var current_state: TurnState = TurnState.PLAYER_TURN
var turn_delay: float = 0.05


func _ready():
	emit_signal("turn_changed", current_state)


func process_turn():
	# Перейти в ENVIRONMENT_TURN
	current_state = TurnState.ENVIRONMENT_TURN
	emit_signal("turn_changed", current_state)
	await _handle_environment_turn()
	
	# Перейти в ENEMY_TURN
	current_state = TurnState.ENEMY_TURN
	emit_signal("turn_changed", current_state)
	await _handle_enemy_turn()
	
	# Вернуться в PLAYER_TURN
	current_state = TurnState.PLAYER_TURN
	emit_signal("turn_changed", current_state)

func is_player_turn() -> bool:
	return current_state == TurnState.PLAYER_TURN

# Внутренняя функция для фазы окружения (с задержкой)
func _handle_environment_turn():
	# Здесь будет логика окружения (ловушки и т.д.), но пока пусто
	# Симуляция: Задержка
	await get_tree().create_timer(turn_delay).timeout

# Внутренняя функция для фазы врагов (с задержкой)
func _handle_enemy_turn():
	# Здесь будет логика врагов (perform_turn() для каждого), но пока пусто
	# Симуляция: Задержка
	await get_tree().create_timer(turn_delay).timeout
