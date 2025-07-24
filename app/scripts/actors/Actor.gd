# res://app/scripts/actors/Actor.gd
# Base class for characters (actors) in the game.
class_name Actor
extends Node2D

signal action_requested(direction: Vector2i)

@export var stats: StatsComponent

var grid_position: Vector2i
var components: Dictionary = {}  # { "component_name": ActorComponent }
var sprite: Sprite2D


# Adds a component to the actor and initializes it.
func add_component(component: ActorComponent) -> void:
	if not is_instance_valid(component):
		return
	
	components[component.name] = component
	component.init(self)


# Checks if the actor has a component by name.
func has_component(component_name: String) -> bool:
	return components.has(component_name)


# Gets a component by name or returns a default.
func get_component(component_name: String, default = null) -> ActorComponent:
	return components.get(component_name, default)


# Moves the actor to a new grid position.
func move(direction: Vector2i) -> void:
	var target_pos: Vector2i = grid_position + direction
	GridManager.move_actor(self, target_pos)


# Applies damage to the actor.
func take_damage(amount: int) -> void:
	if not stats:
		return
	
	stats.current_hp -= amount
	if stats.current_hp <= 0:
		die()


# Handles actor death: removes from grid and frees the node.
func die() -> void:
	GridManager.remove_actor(self)
	queue_free()


# Performs an action in the given direction.
func perform_action(direction: Vector2i) -> void:
	if not _can_perform_action():
		return
	
	_flip_sprite(direction)
	
	var target_pos: Vector2i = grid_position + direction
	var target_actor: Actor = GridManager.get_actor_at(target_pos)
	
	if target_actor:
		_attack(target_actor)
	elif GridManager.is_walkable(target_pos):
		_move_and_update(direction)
	else:
		# Path blocked, do nothing.
		return
	
	TurnManager.process_turn()


# Checks if the actor can perform an action (e.g., player's turn).
func _can_perform_action() -> bool:
	if is_in_group("player") and not TurnManager.is_player_turn():
		return false
	return true


# Flips the sprite based on movement direction.
func _flip_sprite(direction: Vector2i) -> void:
	if direction.x != 0:
		sprite.flip_h = direction.x < 0


# Attacks a target actor.
func _attack(target: Actor) -> void:
	if not stats:
		return
	target.take_damage(stats.damage)


# Moves the actor and updates FOV.
func _move_and_update(direction: Vector2i) -> void:
	move(direction)
	update_fov()


# Updates field of view (FOV) if the actor has a light component.
func update_fov() -> void:
	var light_component: LightSourceComponent = get_component("LightSourceComponent")
	if light_component:
		light_component.update_light()
