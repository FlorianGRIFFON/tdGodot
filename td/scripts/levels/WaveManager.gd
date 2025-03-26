# WaveManager.gd
extends Node2D

# Enemy scene references (map creep names to scenes)
var enemy_scenes = {
	"enemy_goblin": preload("res://scenes/enemies/Goblin.tscn"),
	"enemy_bandit": preload("res://scenes/enemies/Bandit.tscn"),
	"enemy_viking": preload("res://scenes/enemies/Viking.tscn")
}

# Start and end positions
var path_starts = {
	1: Vector2i(25, 32),
	2: Vector2i(25, 32),
	3: Vector2i(50, 25)
}
var path_ends = {
	1: Vector2i(27, -1),
	2: Vector2i(27, -1),
	3: Vector2i(27, -1),
}

# Navigation layers
var nav_layers = {
	1: (1 << 0) | (1 << 9) | (1 << 12),			# 1LEFT_ROAD
	2: (1 << 1) | (1 << 10) | (1 << 12),		# 1MIDDLE_ROAD
	3: (1 << 2) | (1 << 11) | (1 << 12),		# 1RIGHT_ROAD
	4: (1 << 3) | (1 << 9) | (1 << 12),			# 2LEFT_ROAD
	5: (1 << 4) | (1 << 10) | (1 << 12),		# 2MIDDLE_ROAD
	6: (1 << 5) | (1 << 11) | (1 << 12),		# 2RIGHT_ROAD
	7: (1 << 6) | (1 << 9) | (1 << 12),			# 3LEFT_ROAD
	8: (1 << 7) | (1 << 10) | (1 << 12),		# 3MIDDLE_ROAD
	9: (1 << 8) | (1 << 11) | (1 << 12),		# 3RIGHT_ROAD
}

# Mapping path_index to nav_layers sub-path ranges
var sub_path_ranges = {
	1: [1, 2, 3],  # path_index 1 → nav_layers 1-3
	2: [4, 5, 6],  # path_index 2 → nav_layers 4-6
	3: [7, 8, 9]   # path_index 3 → nav_layers 7-9
}

var wave_data: Dictionary
var current_group_idx: int = 0
var current_wave_idx: int = 0
var spawn_counts: Dictionary = {}
var spawn_timers: Dictionary = {}

var group_timer: Timer
var wave_timer: Timer
var tilemap: TileMapLayer

func initialize(data: Dictionary, group_timer_ref: Timer, wave_timer_ref: Timer, tilemap_ref: TileMapLayer) -> void:
	wave_data = data
	group_timer = group_timer_ref
	wave_timer = wave_timer_ref
	tilemap = tilemap_ref
	# Connect signals programmatically
	start_wave_system()


func start_wave_system():
	if current_group_idx >= wave_data["groups"].size():
		print("All waves completed!")
		return
	var group = wave_data["groups"][current_group_idx]
	group_timer.wait_time = group["interval"]
	group_timer.one_shot = true
	group_timer.start()
	print("Starting group ", current_group_idx)


func _on_group_timer_timeout():
	if current_wave_idx >= wave_data["groups"][current_group_idx]["waves"].size():
		current_group_idx += 1
		current_wave_idx = 0
		start_wave_system()
		return
	var wave = wave_data["groups"][current_group_idx]["waves"][current_wave_idx]
	var delay = wave.get("delay", 0.1)  # Default to 0.1s if missing
	if delay <= 0:
		delay = 0.1  # Ensure positive value
	wave_timer.wait_time = delay
	wave_timer.one_shot = true
	wave_timer.start()
	print("Starting wave ", current_wave_idx, " in group ", current_group_idx)


func _on_wave_timer_timeout():
	var wave = wave_data["groups"][current_group_idx]["waves"][current_wave_idx]
	spawn_counts.clear()
	for timer in spawn_timers.values():
		timer.queue_free()
	spawn_timers.clear()
	
	var cumulative_delay = 0.0  # Track total delay from wave start
	for i in range(wave["spawns"].size()):
		var spawn = wave["spawns"][i]
		spawn_counts[i] = 0
		var spawn_timer = Timer.new()
		spawn_timer.wait_time = spawn["interval"]
		spawn_timer.one_shot = false
		spawn_timer.connect("timeout", Callable(self, "_spawn_enemy").bind(i))
		add_child(spawn_timer)
		spawn_timers[i] = spawn_timer
		
		# Apply delay if cumulative_delay > 0
		if cumulative_delay > 0:
			var delay_timer = Timer.new()
			delay_timer.wait_time = cumulative_delay
			delay_timer.one_shot = true
			delay_timer.connect("timeout", Callable(self, "_start_spawn_timer").bind(spawn_timer, i, spawn["creep"], spawn["path"]))
			add_child(delay_timer)
			delay_timer.start()
		else:
			_start_spawn_timer(spawn_timer, i, spawn["creep"], spawn["path"])
		
		# Add this spawn's interval_next to the cumulative delay for the next spawn
		cumulative_delay += spawn["interval_next"]


func _start_spawn_timer(timer: Timer, spawn_idx: int, creep: String, path: int):
	timer.start()
	print("Started spawn ", spawn_idx, ": ", creep, " on path ", path)


func _spawn_enemy(spawn_idx: int):
	if current_wave_idx >= wave_data["groups"][current_group_idx]["waves"].size():
		for timer in spawn_timers.values():
			timer.stop()
		return
	var wave = wave_data["groups"][current_group_idx]["waves"][current_wave_idx]
	var spawn = wave["spawns"][spawn_idx]
	var creep_name = spawn["creep"]
	if creep_name in enemy_scenes:
		var enemy_instance = enemy_scenes[creep_name].instantiate()
		var path_idx = int(spawn["path"])
		var fixed_sub_path = int(spawn["fixed_sub_path"])
		var nav_idx: int
		if fixed_sub_path == 0:
			var sub_paths = sub_path_ranges[path_idx]
			nav_idx = sub_paths[randi_range(0, sub_paths.size() - 1)]
		else:
			nav_idx = sub_path_ranges[path_idx][fixed_sub_path - 1]
		
		if path_idx in path_starts and path_idx in path_ends and nav_idx in nav_layers:
			var start_pos = tilemap.map_to_local(path_starts[path_idx]) * 0.25
			var end_pos = tilemap.map_to_local(path_ends[path_idx]) * 0.25
			var nav_layer = nav_layers[nav_idx]
			if spawn_counts[spawn_idx] < spawn["max"]:
				get_parent().add_child(enemy_instance)
				enemy_instance.initialize(start_pos, end_pos, nav_layer)
				spawn_counts[spawn_idx] += 1
				print("Spawned ", creep_name, " (", spawn_counts[spawn_idx], "/", spawn["max"], ") on path ", path_idx, " nav_idx ", nav_idx, " at ", start_pos)
			if spawn_counts[spawn_idx] >= spawn["max"]:
				spawn_timers[spawn_idx].stop()
				spawn_timers[spawn_idx].queue_free()
				spawn_timers.erase(spawn_idx)
				# Check if all spawns are done
				var all_done = true
				for idx in spawn_counts.keys():
					if spawn_counts[idx] < wave["spawns"][idx]["max"]:
						all_done = false
						break
				if all_done:
					print("Wave ", current_wave_idx, " completed!")
					current_wave_idx += 1
					group_timer.start()
		else:
			push_error("Invalid path_idx: " + str(path_idx) + " or nav_idx: " + str(nav_idx))
