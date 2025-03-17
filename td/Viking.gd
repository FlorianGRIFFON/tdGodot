# Viking.gd
extends Enemy
class_name Viking

func _ready() -> void:
	speed = 80.0
	def = 20.0
	print("Viking spawned at ", position)
