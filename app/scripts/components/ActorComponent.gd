# res://app/scripts/components/ActorComponent.gd
# Actor component base class
class_name ActorComponent
extends Node


var actor: Node


func init(owner_actor: Actor) -> void:
	actor = owner_actor
