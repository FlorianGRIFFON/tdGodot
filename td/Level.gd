# Level.gd
extends Node2D

# Wave data
var wave_data: Dictionary
var lives: int = 20
var cash: int = 1000
var selected_tower: PackedScene = null

@onready var tilemap = $TileMapLayer
@onready var wave_manager = $WaveManager
@onready var camera = $Camera2D
@onready var group_timer = $GroupTimer
@onready var wave_timer = $WaveTimer

func _ready():
	load_wave_data("res://levels/level1.json")
	wave_manager.initialize(wave_data, group_timer, wave_timer, tilemap)  # Pass timers and tilemap
	camera.initialize(tilemap)  # Pass tilemap to camera

func _input(event):
	if event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
		if selected_tower:
			var tower = selected_tower.instantiate()
			if cash >= tower.build_cost:
				cash -= tower.build_cost
				tower.position = get_global_mouse_position()
				add_child(tower)
				print("Placed ", tower.tower_id, " for ", tower.build_cost, ". Cash: ", cash)
				selected_tower = null
			else:
				print("Not enough cash!")
				tower.queue_free()

func buy_tower(tower_scene: PackedScene):
	selected_tower = tower_scene

func upgrade_tower(tower: Tower, next_level: int = -1):
	var cost = tower.get_cost()
	if cost > 0 and cash >= cost:
		if tower.upgrade(next_level):
			cash -= cost
			print("Upgraded ", tower.tower_id, " to level ", tower.upgrade_level, " for ", cost, ". Cash: ", cash)
		else:
			print("Upgrade failed (invalid path or max level)!")
	else:
		print("Not enough cash! Need ", cost, ", have ", cash)

func sell_tower(tower: Tower):
	var sell_value = tower.sell()
	cash += sell_value
	print("Sold ", tower.tower_id, " for ", sell_value, ". Cash: ", cash)

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
