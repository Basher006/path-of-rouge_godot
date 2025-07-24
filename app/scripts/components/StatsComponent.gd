# res://app/scripts/components/StatsComponent.gd
# Resource for holding actor stats.
class_name StatsComponent
extends Resource

@export var max_hp: int = 1
@export var current_hp: int = 1
@export var damage: int = 1


# Initializes stats to default values.
func initialize_stats() -> void:
	current_hp = max_hp
