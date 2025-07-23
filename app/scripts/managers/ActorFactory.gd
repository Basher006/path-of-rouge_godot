# res://app/scripts/managers/ActorFactory.gd
# Create actors.
extends Node


const ACTOR_DB_PATH = "res://data/actors.json"
const ACTOR_SCENE = preload("res://app/scripts/actors/actor.tscn")
const COMPONENTS = {
	"StatsComponent": preload("res://app/scripts/components/StatsComponent.gd"),
	"PlayerInputComponent": preload("res://app/scripts/components/PlayerInputComponent.gd"),
	"LightSourceComponent": preload("res://app/scripts/components/LightSourseComponent.gd"),
	"CameraComponent": preload("res://app/scripts/components/CameraComponent.gd")
}

var actor_data: Dictionary = {}


func _ready() -> void:
	var file = FileAccess.open(ACTOR_DB_PATH, FileAccess.READ)
	if file == null:
		push_error("Failed to open actor database: %s" % ACTOR_DB_PATH)
		return
	
	var json_data = JSON.parse_string(file.get_as_text())
	if json_data:
		actor_data = json_data
	else:
		push_error("Failed to parse JSON from: %s" % ACTOR_DB_PATH)


func create_actor(actor_id: String, position: Vector2i) -> Actor:
	if not actor_data.has(actor_id):
		push_error("Actor ID '%s' not found in database." % actor_id)
		return null
		
	var template: Dictionary = actor_data[actor_id]
	var actor_instance: Actor = ACTOR_SCENE.instantiate() as Actor
	
	actor_instance.name = template.get("name", "Unnamed Actor")
	actor_instance.grid_position = position
	actor_instance.position = G.grid_to_world(position)
	
	var texture_path = template.get("texture_path", "")
	if not texture_path.is_empty():
		var sprite_node: Sprite2D = actor_instance.get_node("Sprite2D")
		if sprite_node:
			sprite_node.texture = load(texture_path)
			sprite_node.z_index = 1
			sprite_node.position = Vector2(8, 6)
			
			actor_instance.sprite = sprite_node
		else:
			push_warning("Actor '%s' has no Sprite2D node in its scene." % actor_id)
	
	var components_data: Dictionary = template.get("components", {})
	for component_name in components_data:
		var component_data: Dictionary = components_data[component_name]
		
		# 1. Проверяем, что компонент есть в нашей карте
		if not COMPONENTS.has(component_name):
			push_warning("Component class '%s' not found in COMPONENTS map." % component_name)
			continue
		
		# 2. Создаем экземпляр из предзагруженного скрипта
		var component_script = COMPONENTS[component_name]
		var new_component = component_script.new()
		
		# 3. Дальнейшая логика остается почти такой же
		if new_component is Resource:
			for key in component_data:
				new_component.set(key, component_data[key])
			
			var prop_name = component_name.to_snake_case().rstrip("_component")
			actor_instance.set(prop_name, new_component)
			
			if new_component is StatsComponent:
				new_component.initialize_stats()
		
		elif new_component is Node:
			# Заполняем экспортируемые данные ДО того, как добавить на сцену
			for key in component_data:
				new_component.set(key, component_data[key])
			
			new_component.name = component_name
			actor_instance.add_child(new_component)
			
			if new_component is ActorComponent:
				actor_instance.add_component(new_component)
			else:
				# Если это просто Node, а не наш компонент, добавляем по-старому
				actor_instance.add_child(new_component)
		else:
			push_warning("Component '%s' is not a Resource or a Node." % component_name)
			if new_component is Object and not new_component is Script:
				new_component.free()
	
	if actor_id == "player":
		actor_instance.add_to_group("player")

	return actor_instance
