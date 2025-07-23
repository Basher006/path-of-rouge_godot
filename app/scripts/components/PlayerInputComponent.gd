# res://app/scripts/components/PlayerInputComponent.gd
# Control player imputs.
class_name PlayerInputComponent
extends ActorComponent # Наследуемся от нашего базового компонента

func _unhandled_input(event: InputEvent) -> void:
	# Проверяем, наш ли сейчас ход.
	# Если нет, игнорируем любой ввод.
	if not TurnManager.is_player_turn():
		return
	
	# Определяем вектор движения
	var move_direction = Vector2i.ZERO
	if event.is_action_pressed("Right"):
		move_direction = Vector2i.RIGHT
	elif event.is_action_pressed("Left"):
		move_direction = Vector2i.LEFT
	elif event.is_action_pressed("Down"):
		move_direction = Vector2i.DOWN
	elif event.is_action_pressed("Up"):
		move_direction = Vector2i.UP
	
	# Если была нажата одна из клавиш движения
	if move_direction != Vector2i.ZERO:
		# Сообщаем нашему владельцу (Actor), что мы хотим совершить действие.
		# Мы не решаем, можно ли это сделать. Мы просто передаем намерение.
		actor.action_requested.emit(move_direction)
		
		# "Съедаем" событие, чтобы оно не обрабатывалось дальше.
		#get_viewport().set_input_as_handled()
