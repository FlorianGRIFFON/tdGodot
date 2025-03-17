# Level.gd
extends Node2D

# Wave data
var wave_data: Dictionary
var lives: int = 20  # Player lives, set by JSON

@onready var tilemap = $TileMapLayer
@onready var wave_manager = $WaveManager
@onready var camera = $Camera2D
@onready var group_timer = $GroupTimer
@onready var wave_timer = $WaveTimer

func _ready():
	load_wave_data("res://levels/level1.json")
	wave_manager.initialize(wave_data, group_timer, wave_timer, tilemap)  # Pass timers and tilemap
	camera.initialize(tilemap)  # Pass tilemap to camera


func load_wave_data(path: String):
	var file = FileAccess.open(path, FileAccess.READ)
	if file:
		var json_text = file.get_as_text()
		wave_data = JSON.parse_string(json_text)
		file.close()
		lives = wave_data.get("lives", 20)
		print("Wave data loaded: ", wave_data, " Lives: ", lives)
	else:
		push_error("Failed to load wave data from: " + path)


func enemy_reached_end(enemy: Enemy) -> void:
	lives -= int(enemy.penalty)  # Reduce lives by enemy's penalty value
	print("Enemy reached end! Lives remaining: ", lives)
	if lives <= 0:
		print("Game Over! No lives remaining.")
		# Add game over logic here (e.g., pause, show UI)
