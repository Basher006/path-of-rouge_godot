# res://app/scripts/actors/Actor.gd
# Characters base class. 
class_name Actor
extends Node2D


signal action_requested(direction: Vector2i)



@export var stats: StatsComponent

var grid_position: Vector2i
var components: Dictionary = {} # "{ name: component }"
var sprite: Sprite2D


func add_component(component: ActorComponent) -> void:
	# Проверяем, что компонент не null и является узлом.
	if not is_instance_valid(component) or not component is Node:
		return
	
	# Добавляем его как дочерний узел
	#add_child(component)
	
	# Сохраняем ссылку в наш словарь
	# component.name будет установлен фабрикой
	components[component.name] = component
	
	# Инициализируем компонент, передавая ему ссылку на самого себя
	component.init(self)

func has_component(name_: String) -> bool:
	return components.has(name_)

func get_component(name_: String, default) -> ActorComponent:
	if has_component(name_):
		return components[name_]
	else:
		return default

# Функция перемещения
func move(direction: Vector2i):
	var target_pos = grid_position + direction
	# Обновляем позицию в GridManager и свою внутреннюю позицию.
	# Эту логику мы скоро перенесем в GridManager.
	GridManager.move_actor(self, target_pos)


# Функция получения урона.
# Будет вызываться другими актерами.
func take_damage(amount: int):
	# Проверяем, есть ли у нас вообще компонент статистики.
	if not stats:
		return

	stats.current_hp -= amount
	#print("{name} takes {amount} damage. {stats.current_hp}/{stats.max_hp} HP left.")
	print("s% takes s% damage. s%/%s HP left." % [name, amount, stats.current_hp, stats.max_hp])

	if stats.current_hp <= 0:
		die()

# Функция смерти
func die():
	#print(f"{name} is dead.")
	print("%s is dead." % name)
	# TODO: Показать анимацию, дропнуть лут и т.д.
	
	# Убираем себя с карты
	GridManager.remove_actor(self)
	# Удаляем узел из сцены
	queue_free()

# Функция для выполнения действия
func perform_action(direction: Vector2i) -> void:
	# 1. Проверяем, наш ли сейчас ход (для игрока).
	# Эта проверка уже есть в PlayerInputComponent, но дублирование не повредит,
	# особенно когда появятся враги, у которых нет InputComponent.
	if get_tree().get_nodes_in_group("player").has(self): # Проверяем, игрок ли это
		if not TurnManager.is_player_turn():
			return
	
	# флипаем спрайт в направленее жвижения. 
	if direction.x != 0:
		sprite.flip_h = direction.x < 0
	
	# 2. Определяем целевую клетку
	var target_pos = grid_position + direction
	
	# 3. Проверяем, что в этой клетке
	var target_actor = GridManager.get_actor_at(target_pos)
	
	if target_actor:
		# Если там другой актер - атакуем!
		attack(target_actor)
		TurnManager.process_turn()
	elif GridManager.is_walkable(target_pos):
		# Если можно пройти, двигаемся
		GridManager.move_actor(self, target_pos) # Используем централизованный метод
		# Обновляем освещение после движения
		update_fov()
		TurnManager.process_turn()
	else:
		# Если там стена, ничего не делаем, ход не тратится
		#print("Path to %s is blocked." % target_pos)
		pass

# Новая функция атаки
func attack(target: Actor):
	if not stats: return # Не можем атаковать без статов
	
	#print(f"{name} attacks {target.name}!")
	print("%s attacks %s!" % [name, target.name])
	target.take_damage(stats.damage)

func update_fov():
	# Проверяем, есть ли у нас компонент света, по его имени.
	if components.has("LightSourceComponent"):
		var light_component: LightSourceComponent = components["LightSourceComponent"]
		light_component.update_light()
