# Enemy.gd
class_name Enemy
extends CharacterBody2D

@onready var nav: NavigationAgent2D = $NavigationAgent2D
@onready var sprite: AnimatedSprite2D = $AnimatedSprite2D
var navigation_ready = false

@export var hp: float = 100.0
@export var speed: float = 100.0

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
	
	var direction = (next_path_position - global_position).normalized()
	if abs(direction.x) > abs(direction.y):
		direction.y = 0  # Prioritize horizontal movement
	else:
		direction.x = 0  # Prioritize vertical movement
	update_sprite_direction(direction)

func _on_navigation_agent_2d_velocity_computed(safe_velocity: Vector2) -> void:
	velocity = safe_velocity

# Placeholder function - MUST be overridden by child classes
func update_sprite_direction(direction: Vector2) -> void:
	push_error("Error: update_sprite_direction must be implemented by child class!")
	pass
