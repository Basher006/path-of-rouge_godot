# res://app/scripts/components/CameraComponent.gd
# Default Player Camera.
class_name CameraComponent
extends ActorComponent


var prelaod_camera = preload("res://app/scripts/components/CameraComponent.tscn")


func init(owner_actor: Actor) -> void:
	print("camera ebanaya has be init!")
	super.init(owner_actor)
	
	var camera_instance = prelaod_camera.instantiate()
	owner_actor.add_child(camera_instance)
