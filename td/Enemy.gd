# Enemy.gd
class_name Enemy
extends CharacterBody2D

@onready var nav: NavigationAgent2D = $NavigationAgent2D
@onready var sprite: AnimatedSprite2D = $AnimatedSprite2D
var navigation_ready = false

# Global resistance stats
@export var hp: float = 100.0
@export var def: float = 0.0
@export var mdef: float = 0.0

# Global speed stat
@export var speed: float = 100.0

# Global attack stats
@export var min_atk: float = 5.0
@export var max_atk: float = 10.0

# Global level related stats
@export var bounty: float = 10.0
@export var penalty: float = 1.0

# Custom initialization function with start_pos, end_pos, and nav_layer
func initialize(start_pos: Vector2, end_pos: Vector2, nav_layer: int) -> void:
	position = start_pos
	await get_tree().process_frame
	navigation_ready = true
	nav.target_position = end_pos
	nav.set_navigation_layers(nav_layer)  # Apply the passed navigation layer
	print("Enemy initialized at ", position, " heading to ", end_pos, " with nav layer: ", nav_layer)


func _physics_process(_delta: float) -> void:
	if not navigation_ready:
		return
	
	var next_path_position = nav.get_next_path_position()
	var new_velocity = global_position.direction_to(next_path_position) * speed
	_on_navigation_agent_2d_velocity_computed(new_velocity)
	move_and_slide()
	
	# Check if enemy reached the end
	if global_position.distance_to(nav.target_position) < 5.0:  # Small threshold
		reached_end()
	
	var direction = (next_path_position - global_position).normalized()
	if abs(direction.x) > abs(direction.y):
		direction.y = 0  # Prioritize horizontal movement
	else:
		direction.x = 0  # Prioritize vertical movement
	update_sprite_direction(direction)


func _on_navigation_agent_2d_velocity_computed(safe_velocity: Vector2) -> void:
	velocity = safe_velocity


# Animate the sprite in correct direction dynamically
func update_sprite_direction(direction: Vector2) -> void:
	# Get the scene name dynamically (e.g., "Goblin" from "Goblin.tscn")
	var scene_name = get_filename_prefix().to_lower()  # e.g., "goblin"
	
	# Determine animation based on direction
	if direction.length() < 0.1:  # Idle if direction is near zero
		sprite.play(scene_name + "_idle")
	else:
		if abs(direction.x) > abs(direction.y):  # Horizontal priority
			if direction.x < 0:
				sprite.play(scene_name + "_walk_left")
			else:
				sprite.play(scene_name + "_walk_right")
		else:  # Vertical priority
			if direction.y < 0:
				sprite.play(scene_name + "_walk_up")
			else:
				sprite.play(scene_name + "_walk_down")


func get_filename_prefix() -> String:
	# Extract the base name from the scene file (e.g., "Goblin" from "res://Goblin.tscn")
	var scene_path = get_scene_file_path()
	if scene_path.is_empty():
		push_warning("Enemy has no scene file path, using node name: " + name)
		return name  # Fallback to node name if instantiated manually
	var file_name = scene_path.get_file().get_basename()  # e.g., "Goblin"
	return file_name


func reached_end() -> void:
	# Notify Level1 to reduce lives and despawn
	get_parent().enemy_reached_end(self)  # Call method in Level1.gd
	queue_free()  # Despawn the enemy
