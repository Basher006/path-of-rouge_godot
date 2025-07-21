# res://app/scipts/Player.gd
# Скрипт игрока. 
extends Node2D


const LIGHT_SOURCE_PREFAB = preload("res://app/scenes/light_source_component.tscn")


@onready var move_timer: Timer = $MoveTimer  # Убедись, что Timer добавлен в сцену и назван MoveTimer
@onready var sprite: Sprite2D = $PlayerSprite  # Ссылка на спрайт


# Настройки (можно настроить в инспекторе или здесь)
@export var initial_delay: float = 0.2  # Задержка перед началом быстрого движения (в секундах)
@export var repeat_delay: float = 0.05  # Интервал повторяющегося движения (в секундах)

var current_direction: Vector2 = Vector2.ZERO
var light_component: LightSourceComponent


func _ready() -> void:
	# Добавляем источник света.
	var light_instance = LIGHT_SOURCE_PREFAB.instantiate()
	add_child(light_instance)
	# Настройка света.
	light_component = light_instance
	light_component.radius = 12
	light_component.energy = 1.0
	light_component.last_grid_pos = get_grid_pos()
	# Применение света после инициализации.
	light_component.update()
	
	# Настраиваем таймер.
	move_timer.one_shot = false
	move_timer.autostart = false
	move_timer.timeout.connect(_on_MoveTimer_timeout)
	
	# Двигаем пресонажа в нужную клетку при старте (DEBUG ONLY!)
	global_position = Vector2i(128, 68)

func _process(_delta: float) -> void:
	var input_dir: Vector2 = get_input_direction()
	if input_dir != Vector2.ZERO:
		if input_dir != current_direction:
			# Новое направление: двигаемся сразу и запускаем таймер с initial_delay
			move(input_dir)
			current_direction = input_dir
			move_timer.start(initial_delay)
	else:
		# Нет ввода: сбрасываем и останавливаем таймер
		current_direction = Vector2.ZERO
		move_timer.stop()

func get_input_direction() -> Vector2:
	var dir: Vector2 = Vector2.ZERO
	if Input.is_action_pressed("Right"):
		dir = Vector2.RIGHT
	elif Input.is_action_pressed("Left"):
		dir = Vector2.LEFT
	elif Input.is_action_pressed("Down"):
		dir = Vector2.DOWN
	elif Input.is_action_pressed("Up"):
		dir = Vector2.UP
	return dir

func _on_MoveTimer_timeout() -> void:
	if current_direction != Vector2.ZERO and get_input_direction() == current_direction:
		# Повторяем движение и перезапускаем таймер с repeat_delay
		move(current_direction)
		move_timer.start(repeat_delay)
	else:
		move_timer.stop()

func move(dir: Vector2) -> void:
	# Flip sprite по X
	if dir.x > 0:
		sprite.flip_h = false
	elif dir.x < 0:
		sprite.flip_h = true
	# Рассчитываем целевую grid-позицию (конвертируем текущую world -> grid, добавляем dir)
	var current_grid = get_grid_pos()
	var target_grid = current_grid + Vector2i(dir)  # dir как Vector2i (RIGHT = (1,0) и т.д.)
	
	# Проверка: можно ли переместиться? (is_walkable ожидает Vector2i — grid pos)
	if GridManager.is_walkable(target_grid):
		var target_world_pos = G.grid_to_world(target_grid)
		position = target_world_pos
		light_component.move_light(target_grid)

func get_grid_pos() -> Vector2i:
	return G.world_to_grid(position)
