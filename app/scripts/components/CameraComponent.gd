# res://app/scripts/components/CameraComponent.gd
# Component for attaching a camera to the actor.
class_name CameraComponent
extends ActorComponent

const CAMERA_SCENE: PackedScene = preload("res://app/scripts/components/CameraComponent.tscn")


# Initializes the camera component.
func init(owner_actor: Actor) -> void:
	super.init(owner_actor)
	
	var camera_instance = CAMERA_SCENE.instantiate()
	owner_actor.add_child(camera_instance)
