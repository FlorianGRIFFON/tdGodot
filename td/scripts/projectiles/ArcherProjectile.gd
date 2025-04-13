extends Projectile

func _ready():
	var anim_name = "archer_projectile" + str(upgrade_level)
	if sprite.sprite_frames.has_animation(anim_name):
		sprite.play(anim_name)
	else:
		sprite.play("archer_projectile0")
	super._ready()

func _apply_effect():
	if tower and target and is_instance_valid(target):
		var damage = randi_range(tower.min_atk, tower.max_atk)
		target.take_damage(damage)
		# Piercing for level 4
		if upgrade_level == 4:
			var enemies = tower.range_area.get_overlapping_bodies()
			for enemy in enemies:
				if enemy != target and is_instance_valid(enemy):
					enemy.take_damage(damage / 2.0)  # Half damage to others
