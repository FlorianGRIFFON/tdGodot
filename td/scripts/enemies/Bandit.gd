# Bandit.gd
extends Enemy
class_name Bandit

func _ready() -> void:
	speed = 100.0
	print("Bandit spawned at ", position)
