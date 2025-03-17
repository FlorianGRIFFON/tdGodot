# Level1.gd
extends Node2D

# Enemy scene references (map creep names to scenes)
var enemy_scenes = {
	"enemy_goblin": preload("res://Goblin.tscn"),
	"enemy_bandit": preload("res://Bandit.tscn"),
	"enemy_viking": preload("res://Viking.tscn")
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

# Wave data
var wave_data: Dictionary
var current_group_idx: int = 0
var current_wave_idx: int = 0
var spawn_counts: Dictionary = {}  # Track spawn counts per spawn entry
var spawn_timers: Dictionary = {}  # One timer per spawn entry
var lives: int = 20  # Player lives, set by JSON

# Camera control variables
var is_dragging = false
var last_drag_position = Vector2.ZERO
var touch_positions = {}			# For mobile multi-touch
var min_zoom = 0.25					# Initial min zoom (scalar), recalculated
var max_zoom = 2.0					# Maximum zoom level (scalar)
var zoom_step = 0.1					# Zoom change per wheel tick or pinch
var map_size = Vector2.ZERO			# Calculated map size in pixels
var viewport_size = Vector2.ZERO	# Viewport size for zoom calculation

@onready var camera = $Camera2D
@onready var tilemap = $TileMapLayer
@onready var group_timer = $GroupTimer
@onready var wave_timer = $WaveTimer

func _ready():
	tilemap.scale = Vector2(0.25, 0.25)  # Set tilemap scale
	load_wave_data("res://levels/level1.json")
	
	# Store viewport size and calculate map size
	viewport_size = get_viewport_rect().size
	calculate_map_size()
	calculate_min_zoom()	# Set min_zoom based on map size
	center_camera()			# Center the camera on the map
	
	start_wave_system()


func load_wave_data(path: String):
	var file = FileAccess.open(path, FileAccess.READ)
	if file:
		var json_text = file.get_as_text()
		wave_data = JSON.parse_string(json_text)
		file.close()
		lives = wave_data.get("lives", 20)  # Set lives from JSON, default 20
		print("Wave data loaded: ", wave_data, " Lives: ", lives)
	else:
		push_error("Failed to load wave data from: " + path)


func start_wave_system():
	if current_group_idx >= wave_data["groups"].size():
		print("All waves completed!")
		return
	var group = wave_data["groups"][current_group_idx]
	group_timer.wait_time = group["interval"]  # 2 seconds
	group_timer.one_shot = true  # Prevent infinite looping
	group_timer.start()
	print("Starting group ", current_group_idx)


func _on_group_timer_timeout():
	if current_wave_idx >= wave_data["groups"][current_group_idx]["waves"].size():
		current_group_idx += 1
		current_wave_idx = 0
		start_wave_system()
		return
	var wave = wave_data["groups"][current_group_idx]["waves"][current_wave_idx]
	wave_timer.wait_time = wave["delay"]  # 2 seconds
	wave_timer.one_shot = true
	wave_timer.start()
	print("Starting wave ", current_wave_idx, " in group ", current_group_idx)


func _on_wave_timer_timeout():
	# Start all spawns in the wave simultaneously
	var wave = wave_data["groups"][current_group_idx]["waves"][current_wave_idx]
	spawn_counts.clear()
	for timer in spawn_timers.values():
		timer.queue_free()  # Clean up old timers
	spawn_timers.clear()
	
	for i in range(wave["spawns"].size()):
		var spawn = wave["spawns"][i]
		spawn_counts[i] = 0
		var timer = Timer.new()
		timer.wait_time = spawn["interval"]  # 0.5 or 1 second
		timer.one_shot = false
		timer.connect("timeout", Callable(self, "_spawn_enemy").bind(i))
		add_child(timer)
		spawn_timers[i] = timer
		timer.start()
		print("Started spawn ", i, ": ", spawn["creep"], " on path ", spawn["path"])


func _spawn_enemy(spawn_idx: int):
	# Check if wave is still valid
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
				add_child(enemy_instance)
				enemy_instance.initialize(start_pos, end_pos, nav_layer)
				spawn_counts[spawn_idx] += 1
				print("Spawned ", creep_name, " (", spawn_counts[spawn_idx], "/", spawn["max"], ") on path ", path_idx, " nav_idx ", nav_idx, " at ", start_pos)
			if spawn_counts[spawn_idx] >= spawn["max"]:
				spawn_timers[spawn_idx].stop()
				# Check if all spawns are done
				var all_done = true
				for idx in spawn_counts.keys():
					if spawn_counts[idx] < wave["spawns"][idx]["max"]:
						all_done = false
						break
				if all_done:
					for timer in spawn_timers.values():
						timer.stop()
					print("Wave ", current_wave_idx, " completed!")
					current_wave_idx += 1
					group_timer.start()
		else:
			push_error("Invalid path_idx: " + str(path_idx) + " or nav_idx: " + str(nav_idx))


# Set camera position to the middle of the map
func center_camera():
	camera.position = map_size / 2
	camera.zoom = Vector2(1.0, 1.0)	# Start at 1:1 scale to preserve pixel art
	print("Camera centered at: ", camera.position, " with zoom: ", camera.zoom)


func calculate_map_size():
	var used_rect = tilemap.get_used_rect()
	if used_rect.size == Vector2i.ZERO:
		print("Warning: TileMapLayer has no tiles!")
		map_size = Vector2(640, 360)
		return
	var top_left = tilemap.map_to_local(used_rect.position)
	var bottom_right = tilemap.map_to_local(used_rect.end)
	map_size = (bottom_right - top_left).abs() * tilemap.scale
	print("Map size: ", map_size)


func calculate_min_zoom():
	# Calculate min_zoom as a scalar to fit the map in the viewport
	var zoom_x = viewport_size.x / map_size.x	# Zoom to fit width
	var zoom_y = viewport_size.y / map_size.y	# Zoom to fit height
	# Use the smaller zoom value to ensure the entire map fits
	min_zoom = min(zoom_x, zoom_y) + 0.1
	print("Calculated min_zoom: ", min_zoom)
	# Don’t set camera.zoom here; let center_camera() handle initial zoom


func _input(event):
	# Desktop: Mouse button for dragging and zooming
	if event is InputEventMouseButton:
		if event.button_index == MOUSE_BUTTON_LEFT:
			if event.pressed:
				is_dragging = true
				last_drag_position = event.position
			else:
				is_dragging = false
		elif event.button_index == MOUSE_BUTTON_WHEEL_UP and event.pressed:
			zoom_camera(zoom_step)
		elif event.button_index == MOUSE_BUTTON_WHEEL_DOWN and event.pressed:
			zoom_camera(-zoom_step)
	
	# Desktop: Mouse motion for dragging
	if event is InputEventMouseMotion and is_dragging:
		var drag_delta = last_drag_position - event.position
		camera.position += drag_delta / camera.zoom
		last_drag_position = event.position
	
	# Mobile: Touch press/release
	if event is InputEventScreenTouch:
		if event.pressed:
			touch_positions[event.index] = event.position
			if touch_positions.size() == 1:
				is_dragging = true
				last_drag_position = event.position
		else:
			touch_positions.erase(event.index)
			if touch_positions.size() == 0:
				is_dragging = false
	
	# Mobile: Touch drag and pinch
	if event is InputEventScreenDrag:
		touch_positions[event.index] = event.position
		if is_dragging and touch_positions.size() == 1:
			var drag_delta = last_drag_position - event.position
			camera.position += drag_delta / camera.zoom
			last_drag_position = event.position
		elif touch_positions.size() == 2:
			var touch1 = touch_positions[0]
			var touch2 = touch_positions[1]
			var current_dist = touch1.distance_to(touch2)
			var prev_dist = (touch1 - event.relative).distance_to(touch2) if event.index == 0 else touch1.distance_to(touch2 - event.relative)
			if prev_dist > 0:
				var zoom_factor = current_dist / prev_dist
				var new_zoom = camera.zoom.x * zoom_factor	# Use scalar zoom
				new_zoom = clamp(new_zoom, min_zoom, max_zoom)
				camera.zoom = Vector2(new_zoom, new_zoom)


func zoom_camera(delta: float):
	# Apply zoom step as a scalar, keeping x and y equal
	var new_zoom = camera.zoom.x + delta
	new_zoom = clamp(new_zoom, min_zoom, max_zoom)
	camera.zoom = Vector2(new_zoom, new_zoom)


func _process(_delta):
	var effective_viewport_size = get_viewport_rect().size / camera.zoom
	var min_pos = effective_viewport_size / 2
	var max_pos = map_size - effective_viewport_size / 2
	camera.position.x = clamp(camera.position.x, min_pos.x, max_pos.x)
	camera.position.y = clamp(camera.position.y, min_pos.y, max_pos.y)


func enemy_reached_end(enemy: Enemy) -> void:
	lives -= int(enemy.penalty)  # Reduce lives by enemy's penalty value
	print("Enemy reached end! Lives remaining: ", lives)
	if lives <= 0:
		print("Game Over! No lives remaining.")
		# Add game over logic here (e.g., pause, show UI)
