# Tower.gd
extends Node2D
class_name Tower

signal tower_clicked(tower)

enum TargetType { SINGLE, AOE, SPECIAL }

# Stats
var fire_rate: float = 1.0
var min_atk: int = 5
var max_atk: int = 10
var tower_range: float = 150.0
var upgrade_costs: Array = [150, 200, 300, 300]
var projectile_speed: float = 300.0
var target_type: TargetType = TargetType.SINGLE
var tower_id: String = "Generic"
var total_spent: int = 0  # Kept for selling

# Runtime variables
var upgrade_level: int = 0
var target: Node2D = null
var is_building: bool = true

# References
@onready var range_area = $RangeArea
@onready var fire_timer = $FireTimer
@onready var base_sprite = $BaseSprite
@onready var weapon_sprite = $WeaponSprite
@onready var dust_sprite = $DustSprite
@onready var projectile_spawn = $ProjectileSpawnPoint

func _ready():
	range_area.get_node("CollisionShape2D").shape.radius = tower_range
	fire_timer.wait_time = fire_rate
	base_sprite.visible = false
	weapon_sprite.visible = false
	_play_construction()

func set_build_cost(cost: int):
	total_spent = cost  # Set initial cost from Level.gd

func _play_construction():
	weapon_sprite.visible = false
	if upgrade_level == 0 || upgrade_level == 1:
		base_sprite.play("tower_construct" + str(upgrade_level))
	else:
		base_sprite.play("tower_construct2")
	
	base_sprite.frame = 0
	var frame_to_wait = 4
	if upgrade_level == 0:
		frame_to_wait = 4
	await create_tween().tween_property(base_sprite, "frame", frame_to_wait, 0.5).finished
	base_sprite.visible = true
	weapon_sprite.visible = true
	_update_visuals()
	dust_sprite.visible = true
	dust_sprite.play("tower_dust")
	await dust_sprite.animation_finished
	dust_sprite.stop()
	dust_sprite.visible = false
	is_building = false
	_start_firing()

func _start_firing():
	if not is_building:
		fire_timer.start()

func _on_fire_timer_timeout():
	if not is_building:
		if target:
			_fire_at_target()
		else:
			_find_target()

func _find_target():
	var enemies = range_area.get_overlapping_bodies()
	if enemies.size() > 0:
		target = enemies[0]
		_fire_at_target()
	else:
		target = null

func _fire_at_target():
	var scene_name = get_filename_prefix().to_lower()
	var anim_name = scene_name + "_fire" + str(upgrade_level)
	if target and is_instance_valid(target) and not target.is_queued_for_deletion():
		var direction = (target.global_position - global_position).normalized()
		weapon_sprite.rotation = direction.angle() + PI / 2
		# Get frame count dynamically
		var frame_count = weapon_sprite.sprite_frames.get_frame_count(anim_name) if weapon_sprite.sprite_frames.has_animation(anim_name) else 1
		if frame_count <= 0:
			frame_count = 1  # Avoid division by zero
		# Assume release is at 60% of frames (adjustable)
		var release_frame = max(1, round(frame_count * 1))  # E.g., frame 3 for 5 frames
		# Scale animation speed
		weapon_sprite.speed_scale = frame_count / fire_rate  # E.g., 7 frames, fire_rate=0.8 → 8.75 FPS
		weapon_sprite.play(anim_name)
		# Spawn projectile at release frame
		var spawn_time = fire_rate * release_frame / frame_count
		await get_tree().create_timer(spawn_time).timeout
		weapon_sprite.speed_scale = 1.0
		weapon_sprite.play(scene_name + "_weapon" + str(upgrade_level))
		if target and is_instance_valid(target) and not target.is_queued_for_deletion():
			match target_type:
				TargetType.SINGLE:
					var projectile = _create_projectile()
					if projectile:
						get_parent().add_child(projectile)
				TargetType.AOE:
					var enemies = range_area.get_overlapping_bodies()
					var damage = randi_range(min_atk, max_atk)
					for enemy in enemies:
						if enemy and is_instance_valid(enemy):
							enemy.take_damage(damage)
				TargetType.SPECIAL:
					var projectile = _create_projectile()
					if projectile:
						get_parent().add_child(projectile)
	else:
		print("No valid target to fire at")

func _create_projectile() -> Node2D:
	if not target or not is_instance_valid(target):
		print("Cannot create projectile: invalid target")
		return null
	var projectile = preload("res://scenes/projectiles/Projectile.tscn").instantiate()
	projectile.position = projectile_spawn.global_position
	projectile.target = target
	projectile.speed = projectile_speed
	projectile.tower = self
	return projectile

func upgrade(next_level: int = -1) -> bool:
	if upgrade_level >= 2 and next_level == -1:
		print("Choose an upgrade path: 3 (A) or 4 (B)")
		return false
	
	var cost = get_cost()
	if cost == -1:
		print("Max upgrade reached!")
		return false
	
	if upgrade_level < 2:
		upgrade_level += 1
	else:
		upgrade_level = clamp(next_level, 3, 4)
	
	total_spent += cost  # Add upgrade cost
	is_building = true
	_play_construction()
	_update_stats()
	return true

func _update_stats():
	pass

func _update_visuals():
	var scene_name = get_filename_prefix().to_lower()
	base_sprite.play(scene_name + "_base" + str(upgrade_level))
	weapon_sprite.play(scene_name + "_weapon" + str(upgrade_level))

func get_filename_prefix() -> String:
	var scene_path = get_scene_file_path()
	if scene_path.is_empty():
		push_warning("Tower has no scene file path, using node name: " + name)
		return name
	var file_name = scene_path.get_file().get_basename()
	return file_name

func get_cost() -> int:
	return upgrade_costs[upgrade_level] if upgrade_level < upgrade_costs.size() else -1

func sell() -> int:
	var sell_value = int(total_spent * 0.75)  # 75% of total spent
	queue_free()
	return sell_value

func _on_range_area_body_entered(body):
	if not target and not is_building:
		target = body
		_fire_at_target()

func _on_range_area_body_exited(body):
	if body == target:
		target = null
		_find_target()

func _on_click_area_input_event(_viewport: Node, event: InputEvent, _shape_idx: int) -> void:
	if event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
		if not is_building:  # Assuming you have this check
			print("Tower clicked signal emitted from: ", tower_id)
			emit_signal("tower_clicked", self)
