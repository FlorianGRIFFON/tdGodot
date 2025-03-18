# Level.gd
extends Node2D

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
	wave_manager.initialize(wave_data, group_timer, wave_timer, tilemap)
	camera.initialize(tilemap)
	set_process_input(true)
	buy_tower(preload("res://Archer.tscn"))
	print("Selected tower set to: ", selected_tower)

func _input(event):
	print("Input event: ", event)
	if event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
		if selected_tower:
			var tower = selected_tower.instantiate()
			tower.position = get_global_mouse_position()
			add_child(tower)  # Add first to trigger _ready()
			var build_cost: int = 0
			match tower.tower_id:
				"Archer":
					build_cost = 120
				"Cannon":
					build_cost = 150
				"Mage":
					build_cost = 200
				"Turret":
					build_cost = 100
				_:
					build_cost = 100  # Default
			if cash >= build_cost:
				print("Before placement - Cash: ", cash, " Build cost: ", build_cost)
				cash -= build_cost
				tower.set_build_cost(build_cost)
				print("Placed ", tower.tower_id, " for ", build_cost, ". Cash: ", cash)
				buy_tower(preload("res://Archer.tscn"))
			else:
				print("Not enough cash!")
				tower.queue_free()
		else:
			print("No tower selected!")

func buy_tower(tower_scene: PackedScene):
	selected_tower = tower_scene
	print("Tower selected: ", selected_tower)

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
	lives -= int(enemy.penalty)
	print("Enemy reached end! Lives remaining: ", lives)
	if lives <= 0:
		print("Game Over! No lives remaining.")

func add_cash(amount: float) -> void:
	cash += int(amount)
	print("Gained ", amount, " cash. Total: ", cash)
