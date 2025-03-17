# CameraController.gd
extends Camera2D

var is_dragging = false
var last_drag_position = Vector2.ZERO
var touch_positions = {}			# For mobile multi-touch
var min_zoom = 0.25					# Initial min zoom (scalar), recalculated
var max_zoom = 2.0					# Maximum zoom level (scalar)
var zoom_step = 0.1					# Zoom change per wheel tick or pinch
var map_size = Vector2.ZERO			# Calculated map size in pixels
var viewport_size = Vector2.ZERO	# Viewport size for zoom calculation

var tilemap: TileMapLayer  # Declare without @onready

func initialize(tilemap_ref: TileMapLayer) -> void:
	tilemap = tilemap_ref
	viewport_size = get_viewport_rect().size
	calculate_map_size()
	calculate_min_zoom()
	center_camera()


func center_camera():
	position = map_size / 2
	zoom = Vector2(1.0, 1.0)	# Start at 1:1 scale to preserve pixel art
	print("Camera centered at: ", position, " with zoom: ", zoom)


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
	var zoom_x = viewport_size.x / map_size.x	# Zoom to fit width
	var zoom_y = viewport_size.y / map_size.y	# Zoom to fit height
	min_zoom = min(zoom_x, zoom_y) + 0.1
	print("Calculated min_zoom: ", min_zoom)


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
		position += drag_delta / zoom
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
			position += drag_delta / zoom
			last_drag_position = event.position
		elif touch_positions.size() == 2:
			var touch1 = touch_positions[0]
			var touch2 = touch_positions[1]
			var current_dist = touch1.distance_to(touch2)
			var prev_dist = (touch1 - event.relative).distance_to(touch2) if event.index == 0 else touch1.distance_to(touch2 - event.relative)
			if prev_dist > 0:
				var zoom_factor = current_dist / prev_dist
				var new_zoom = zoom.x * zoom_factor
				new_zoom = clamp(new_zoom, min_zoom, max_zoom)
				zoom = Vector2(new_zoom, new_zoom)


func zoom_camera(delta: float):
	var new_zoom = zoom.x + delta
	new_zoom = clamp(new_zoom, min_zoom, max_zoom)
	zoom = Vector2(new_zoom, new_zoom)


func _process(_delta):
	var effective_viewport_size = get_viewport_rect().size / zoom
	var min_pos = effective_viewport_size / 2
	var max_pos = map_size - effective_viewport_size / 2
	position.x = clamp(position.x, min_pos.x, max_pos.x)
	position.y = clamp(position.y, min_pos.y, max_pos.y)
