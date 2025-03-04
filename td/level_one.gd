extends Node2D

var enemy_1 = preload("res://enemy_1.tscn")

func _ready():
	var start_tile_position = Vector2i(41, 9)  # The tile coordinate of the start
	var end_tile_position = Vector2i(-1, 11)  # The tile coordinate of the exit
	var tilemap = $TileMapLayer  # Reference to your TileMap
	var start_world_position = tilemap.map_to_local(start_tile_position)
	var end_world_position = tilemap.map_to_local(end_tile_position)
	
	set_meta("start_position", start_world_position)
	set_meta("end_position", end_world_position)
	
	spawn_enemy()
	
func _on_enemy_1_spawn_timeout() -> void:
	spawn_enemy()

func spawn_enemy():
	var enemy_1_instance = enemy_1.instantiate()
	
	# Set navigation layers before adding the enemy
	if enemy_1_instance.has_node("NavigationAgent2D"):
		var nav_agent = enemy_1_instance.get_node("NavigationAgent2D")
		
		var base_layer = 1 << 0
		var layer_options = [
			(1 << 1) | (1 << 2),  # Layers 1 and 2
			(1 << 1) | (1 << 3),  # Layers 1 and 3
			(1 << 4)               # Only Layer 4
		]
		
		var chosen_layer = base_layer | layer_options[randi() % layer_options.size()]
		nav_agent.set_navigation_layers(chosen_layer)
		
	add_child(enemy_1_instance)
