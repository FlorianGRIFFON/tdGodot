# ArcherProjectile.gd
extends Projectile

func _ready():
	var anim_name = "archer_projectile" + str(upgrade_level)
	if sprite.sprite_frames.has_animation(anim_name):
		sprite.play(anim_name)
	else:
		sprite.play("archer_projectile0")  # Fallback to level 0
	super._ready()

func _apply_effect():
	super._apply_effect()
