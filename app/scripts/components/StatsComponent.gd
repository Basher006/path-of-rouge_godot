# res://app/scripts/components/StatsComponent.gd
# Hold combat stats.
class_name StatsComponent
extends Resource

# Экспортируем переменные, чтобы их можно было редактировать в инспекторе
# и в нашем JSON-файле.
@export var max_hp: int = 1
@export var current_hp: int = 1
@export var damage: int = 1

# Метод для инициализации/сброса здоровья
func initialize_stats():
	current_hp = max_hp
