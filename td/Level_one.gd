# Level1.gd
extends Node2D

var goblin_scene = preload("res://Goblin.tscn")

# Start and end of level
var start_tile_position = Vector2i(0, 0)
var end_tile_position = Vector2i(1, 1)

# Global navigation layer constants
var ANGLE_RIGHT_ROAD = (1 << 0) | (1 << 1) | (1 << 2)	# Layers 0, 1, 2
var ANGLE_LEFT_ROAD = (1 << 0) | (1 << 1) | (1 << 3)	# Layers 0, 1, 3
var MIDDLE_ROAD = (1 << 0) | (1 << 4)					# Layers 0, 4
var BARACKS_ROAD = (1 << 0) | (1 << 1) | (1 << 2) | (1 << 3) | (1 << 4) | (1 << 5)	# Excluded

# Camera control variables
@onready var camera = $Camera2D
@onready var tilemap = $TileMapLayer
var is_dragging = false
var last_drag_position = Vector2.ZERO
var touch_positions = {}	# For mobile multi-touch
var min_zoom = 0.25			# Initial min zoom (scalar), recalculated
var max_zoom = 2.0			# Maximum zoom level (scalar)
var zoom_step = 0.1			# Zoom change per wheel tick or pinch
var map_size = Vector2.ZERO	# Calculated map size in pixels
var viewport_size = Vector2.ZERO	# Viewport size for zoom calculation

func _ready():
	var start_world_position = tilemap.map_to_local(start_tile_position)
	var end_world_position = tilemap.map_to_local(end_tile_position)
	
	# Store viewport size and calculate map size
	viewport_size = get_viewport_rect().size
	calculate_map_size()
	calculate_min_zoom()	# Set min_zoom based on map size
	center_camera()			# Center the camera on the map
	
	var chosen_layer = select_random_road()
	spawn_goblin(start_world_position, end_world_position, chosen_layer)

func center_camera():
	# Set camera position to the middle of the map
	camera.position = map_size / 2
	camera.zoom = Vector2(1.0, 1.0)	# Start at 1:1 scale to preserve pixel art
	print("Camera centered at: ", camera.position, " with zoom: ", camera.zoom)

func _on_enemy_spawn_timeout() -> void:
	var start_world_position = tilemap.map_to_local(start_tile_position)
	var end_world_position = tilemap.map_to_local(end_tile_position)
	
	var chosen_layer = select_random_road()
	spawn_goblin(start_world_position, end_world_position, chosen_layer)

func select_random_road() -> int:
	var road_options = [ANGLE_RIGHT_ROAD, ANGLE_LEFT_ROAD, MIDDLE_ROAD]
	return road_options[randi() % road_options.size()]

func spawn_goblin(start_pos: Vector2, end_pos: Vector2, nav_layer: int):
	var goblin_instance = goblin_scene.instantiate()
	add_child(goblin_instance)
	goblin_instance.initialize(start_pos, end_pos, nav_layer)

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
