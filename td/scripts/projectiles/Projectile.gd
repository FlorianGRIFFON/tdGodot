extends Node2D
class_name Projectile

var speed: float = 100.0
var target: Node2D = null
var tower: Tower = null
var upgrade_level: int = 0

@onready var sprite = $AnimatedSprite2D

func _ready():
	if not sprite:
		push_warning("Projectile missing AnimatedSprite2D node!")
	else:
		sprite.play("default")

func _process(delta):
	if target and is_instance_valid(target):
		var direction = (target.global_position - global_position).normalized()
		global_position += direction * speed * delta
		sprite.rotation = direction.angle() + PI / 2
		if global_position.distance_to(target.global_position) < 5:
			_apply_effect()
			queue_free()
	else:
		queue_free()

func _apply_effect():
	if tower and target and is_instance_valid(target):
		match tower.target_type:
			Tower.TargetType.SINGLE:
				var damage = randi_range(tower.min_atk, tower.max_atk)
				target.take_damage(damage)
			Tower.TargetType.AOE:
				pass  # Handled by tower
			Tower.TargetType.SPECIAL:
				var damage = randi_range(tower.min_atk, tower.max_atk)
				target.take_damage(damage)
