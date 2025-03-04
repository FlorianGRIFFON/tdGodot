extends CharacterBody2D

@onready var nav: NavigationAgent2D = $NavigationAgent2D
var navigation_ready = false

func _ready() -> void:
	#nav.navigation_layers =
	await get_tree().process_frame
	navigation_ready = true
	var level = get_parent()
	if level.has_meta("start_position"):
		position = level.get_meta("start_position")  # Set starting position
	else:
		print("Error: Start position not set in level metadata!")
	
	if level.has_meta("end_position"):
		var end_position = level.get_meta("end_position")  # Get metadata
		nav.target_position = end_position
	else:
		print("Error: End position not set in level metadata!")
		
func _physics_process(_delta: float) -> void:
	if not navigation_ready:
		return
	
	var next_path_position = nav.get_next_path_position()
	
	var new_velocity = global_position.direction_to(next_path_position) * 100
	_on_navigation_agent_2d_velocity_computed(new_velocity)
	
	## Apply movement
	move_and_slide()
	
	var direction = (next_path_position - global_position).normalized()
	if abs(direction.x) > abs(direction.y):
		direction.y = 0  # Prioritize horizontal movement
	else:
		direction.x = 0  # Prioritize vertical movement

	# Animate movement	
	update_sprite_direction(direction)

func _on_navigation_agent_2d_velocity_computed(safe_velocity: Vector2) -> void:
	velocity = safe_velocity

func update_sprite_direction(direction):
	if direction.x < 0:
		$AnimatedSprite2D.play("walk_left")
	elif direction.x > 0:
		$AnimatedSprite2D.play("walk_right")
	elif direction.y < 0:
		$AnimatedSprite2D.play("walk_up")  # Play animation for moving up
	elif direction.y > 0:
		$AnimatedSprite2D.play("walk_down")  # Play animation for moving down
	else:
		$AnimatedSprite2D.play("idle")  # Idle when not moving
