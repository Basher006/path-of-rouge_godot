# res://app/scripts/managers/ActorFactory.gd
# Factory for creating actors from JSON data.
extends Node

const ACTOR_DB_PATH: String = "res://data/actors.json"
const ACTOR_SCENE: PackedScene = preload("res://app/scripts/actors/actor.tscn")

const COMPONENTS: Dictionary = {
	"StatsComponent": preload("res://app/scripts/components/StatsComponent.gd"),
	"PlayerInputComponent": preload("res://app/scripts/components/PlayerInputComponent.gd"),
	"LightSourceComponent": preload("res://app/scripts/components/LightSourceComponent.gd"),
	"CameraComponent": preload("res://app/scripts/components/CameraComponent.gd")
}

var actor_data: Dictionary = {}


func _ready() -> void:
	_load_actor_data()


# Loads actor data from JSON file.
func _load_actor_data() -> void:
	var file: FileAccess = FileAccess.open(ACTOR_DB_PATH, FileAccess.READ)
	if not file:
		push_error("Failed to open actor database: %s" % ACTOR_DB_PATH)
		return
	
	var json_data = JSON.parse_string(file.get_as_text())
	if json_data:
		actor_data = json_data
	else:
		push_error("Failed to parse JSON from: %s" % ACTOR_DB_PATH)


# Creates an actor instance by ID and position.
func create_actor(actor_id: String, position: Vector2i) -> Actor:
	if not actor_data.has(actor_id):
		push_error("Actor ID '%s' not found in database." % actor_id)
		return null
	
	var template: Dictionary = actor_data[actor_id]
	var actor_instance: Actor = ACTOR_SCENE.instantiate()
	
	actor_instance.name = template.get("name", "Unnamed Actor")
	actor_instance.grid_position = position
	actor_instance.position = G.grid_to_world(position)
	
	_setup_sprite(actor_instance, template.get("texture_path", ""))
	_setup_components(actor_instance, template.get("components", {}))
	
	if actor_id == "player":
		actor_instance.add_to_group("player")
	
	return actor_instance


# Sets up the actor's sprite from texture path.
func _setup_sprite(actor_instance: Actor, texture_path: String) -> void:
	if texture_path.is_empty():
		return
	
	var sprite_node: Sprite2D = actor_instance.get_node("Sprite2D")
	if not sprite_node:
		push_warning("Actor '%s' has no Sprite2D node." % actor_instance.name)
		return
	
	sprite_node.texture = load(texture_path)
	sprite_node.z_index = 1
	sprite_node.position = Vector2(8, 6)
	actor_instance.sprite = sprite_node


# Sets up components from data dictionary.
func _setup_components(actor_instance: Actor, components_data: Dictionary) -> void:
	for component_name in components_data:
		var component_data: Dictionary = components_data[component_name]
		if not COMPONENTS.has(component_name):
			push_warning("Component '%s' not found." % component_name)
			continue
		
		var component_script = COMPONENTS[component_name]
		var new_component = component_script.new()
		
		_apply_component_data(new_component, component_data)
		
		if new_component is Resource:
			_setup_resource_component(actor_instance, new_component, component_name)
		elif new_component is Node:
			_setup_node_component(actor_instance, new_component, component_name)
		else:
			push_warning("Component '%s' is not a Resource or Node." % component_name)
			new_component.free()


# Applies data to a component instance.
func _apply_component_data(component, data: Dictionary) -> void:
	for key in data:
		component.set(key, data[key])


# Sets up a resource-based component (e.g., StatsComponent).
func _setup_resource_component(actor_instance: Actor, component: Resource, component_name: String) -> void:
	var prop_name: String = component_name.to_snake_case().rstrip("_component")
	actor_instance.set(prop_name, component)
	
	if component is StatsComponent:
		component.initialize_stats()


# Sets up a node-based component and adds it to the actor.
func _setup_node_component(actor_instance: Actor, component: Node, component_name: String) -> void:
	component.name = component_name
	actor_instance.add_child(component)
	
	if component is ActorComponent:
		actor_instance.add_component(component)
