# Goblin.gd
extends Enemy
class_name Goblin

func _ready() -> void:
	speed = 150.0
	print("Goblin spawned at ", position)

func update_sprite_direction(direction: Vector2) -> void:
	if direction.x < 0:
		sprite.play("goblin_walk_left")
	elif direction.x > 0:
		sprite.play("goblin_walk_right")
	elif direction.y < 0:
		sprite.play("goblin_walk_up")
	elif direction.y > 0:
		sprite.play("goblin_walk_down")
	else:
		sprite.play("goblin_idle")
