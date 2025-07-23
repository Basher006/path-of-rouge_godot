# res://app/scripts/components/LightSourseComponent.gd
# Component that adds a light source to the level.
class_name LightSourceComponent
extends ActorComponent

@export var radius: int = 8
@export var energy: float = 1.0
@export var levels: Array[float] = [0.4, 0.7]

var last_grid_pos: Vector2i = Vector2i(-1, -1)
var id: int = -1
#var last_calculated_fov: Dictionary = {}


#func _enter_tree() -> void:
	#LightingManager.register_light(self)
#
#
#func _exit_tree() -> void:
	#LightingManager.unregister_light(id)

func init(owner_actor: Actor) -> void:
	# Сначала вызываем родительскую реализацию, чтобы установить ссылку на actor
	super.init(owner_actor)
	
	# Регистрируем этот источник света в LightingManager.
	# Делаем это здесь, а не в _ready, чтобы быть уверенными, что actor уже существует.
	LightingManager.register_light(self)
	
	## Сразу же обновляем свет на стартовой позиции актера
	#update_light()

# Вызывается, когда узел (и его родитель Actor) удаляется из сцены
func _notification(what: int) -> void:
	if what == NOTIFICATION_PREDELETE:
		# Перед удалением снимаем регистрацию с себя
		if LightingManager and id != -1:
			LightingManager.unregister_light(id)


# Обновляет свет на ТЕКУЩЕЙ позиции актера
func update_light() -> void:
	# Проверяем, что actor и LightingManager существуют
	if not is_instance_valid(actor) or not LightingManager:
		print("LIGHT ERROR!!!")
		return
	
	# Передаем себя и ТЕКУЩУЮ позицию актера
	LightingManager.update_light(self, actor.grid_position)

## Updates light at current position.
#func update() -> void:
	#LightingManager.update_light(self, last_grid_pos)
#
#
## Moves light to new position and updates.
#func move_light(new_pos: Vector2i) -> void:
	#LightingManager.update_light(self, new_pos)
	#last_grid_pos = new_pos
