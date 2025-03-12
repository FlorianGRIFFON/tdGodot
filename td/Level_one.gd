# Level1.gd
extends Node2D

var goblin_scene = preload("res://goblin.tscn")

# Global navigation layer constants
var ANGLE_RIGHT_ROAD = (1 << 0) | (1 << 1) | (1 << 2)  # Layers 0, 1, 2
var ANGLE_LEFT_ROAD = (1 << 0) | (1 << 1) | (1 << 3)   # Layers 0, 1, 3
var MIDDLE_ROAD = (1 << 0) | (1 << 4)                  # Layers 0, 4
var BARACKS_ROAD = (1 << 0) | (1 << 1) | (1 << 2) | (1 << 3) | (1 << 4) | (1 << 5)  # Excluded

func _ready():
	var start_tile_position = Vector2i(41, 9)  # The tile coordinate of the start
	var end_tile_position = Vector2i(-1, 11)   # The tile coordinate of the exit
	var tilemap = $TileMapLayer  # Reference to your TileMap
	var start_world_position = tilemap.map_to_local(start_tile_position)
	var end_world_position = tilemap.map_to_local(end_tile_position)
	
	var chosen_layer = select_random_road()
	spawn_goblin(start_world_position, end_world_position, chosen_layer)

func _on_enemy_spawn_timeout() -> void:
	var start_tile_position = Vector2i(41, 9)
	var end_tile_position = Vector2i(-1, 11)
	var tilemap = $TileMapLayer
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
	goblin_instance.initialize(start_pos, end_pos, nav_layer)  # Pass nav_layer to initialize
