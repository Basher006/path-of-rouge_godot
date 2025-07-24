# res://app/scripts/components/LightSourseComponent.gd
# Component for adding a light source to an actor.
class_name LightSourceComponent
extends ActorComponent

@export var radius: int = 8
@export var energy: float = 1.0
@export var levels: Array[float] = [0.4, 0.7]

var id: int = -1


# Initializes the component and registers the light.
func init(owner_actor: Actor) -> void:
	super.init(owner_actor)
	LightingManager.register_light(self)


# Called before the node is deleted.
func _notification(what: int) -> void:
	if what == NOTIFICATION_PREDELETE and id != -1:
		LightingManager.unregister_light(id)


# Updates light at the actor's current position.
func update_light() -> void:
	if not is_instance_valid(actor) or not LightingManager:
		return
	LightingManager.update_light(self, actor.grid_position)
