# res://app/scipts/world.gd
# World initializer: loads and renders the level.
class_name World
extends Node2D

@export var map_renderer: MapRenderer
@export var player: Player

@onready var turn_label = $Canvas/DebugLabel


func _ready() -> void:
	print("Initializing world!")
	_initialize_level()
	player.init(Vector2i(8, 4))
	player.connect("action_taken", Callable(self, "_on_player_action_taken"))
	TurnManager.connect("turn_changed", Callable(self, "_on_turn_changed"))


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
	


func _on_player_action_taken():
	# После действия игрока — запустить цикл в TurnManager
	# Почему? Это завершает ход игрока и переходит к следующим фазам
	TurnManager.process_turn()  # Без await, чтобы не блокировать; добавь await, если нужно ждать окончания

func _on_turn_changed(new_state):
	# Обновить Label в зависимости от состояния
	# Почему match? Читаемо и легко расширяемо
	match new_state:
		TurnManager.TurnState.PLAYER_TURN:
			turn_label.text = "Player's Turn"
		TurnManager.TurnState.ENVIRONMENT_TURN:
			turn_label.text = "Environment's Turn"
		TurnManager.TurnState.ENEMY_TURN:
			turn_label.text = "Enemies' Turn"
