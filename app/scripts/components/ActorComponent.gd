# res://app/scripts/components/ActorComponent.gd
# Base class for actor components.
class_name ActorComponent
extends Node

var actor: Actor


# Initializes the component with its owner actor.
func init(owner_actor: Actor) -> void:
	actor = owner_actor
