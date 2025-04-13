# Archer.gd
extends Tower

func _ready():
	tower_id = "Archer"
	fire_rate = 0.8
	min_atk = 8
	max_atk = 12
	tower_range = 200.0
	upgrade_costs = [110, 160, 250, 250]
	projectile_speed = 200.0
	target_type = TargetType.SINGLE
	super._ready()  # Call base _ready() to set up nodes
	_update_stats()
	_update_visuals()

func _update_stats():
	match upgrade_level:
		1:
			fire_rate = 0.6
			min_atk = 12
			max_atk = 18
			tower_range = 220.0
			projectile_speed = 200.0
		2:
			fire_rate = 0.4
			min_atk = 18
			max_atk = 25
			tower_range = 250.0
			projectile_speed = 200.0
		3:  # Rapid Fire
			fire_rate = 0.2
			min_atk = 20
			max_atk = 30
			tower_range = 260.0
			projectile_speed = 300.0
		4:  # Piercing Shot
			fire_rate = 0.5
			min_atk = 30
			max_atk = 50
			tower_range = 300.0
			projectile_speed = 500.0
	fire_timer.wait_time = fire_rate
	range_area.get_node("CollisionShape2D").shape.radius = tower_range

func _create_projectile() -> Node2D:
	if not target or not is_instance_valid(target):
		print("Cannot create ArcherProjectile: invalid target")
		return null
	var projectile = preload("res://scenes/projectiles/ArcherProjectile.tscn").instantiate()
	projectile.position = projectile_spawn.global_position
	projectile.target = target
	projectile.speed = projectile_speed
	projectile.tower = self
	projectile.upgrade_level = upgrade_level
	return projectile
