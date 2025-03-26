# Goblin.gd
extends Enemy
class_name Goblin

func _ready() -> void:
	speed = 120.0
	print("Goblin spawned at ", position)
