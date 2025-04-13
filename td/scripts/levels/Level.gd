extends Node2D

var wave_data: Dictionary
var lives: int = 20
var cash: int = 1000

@onready var tilemap = $TileMapLayer
@onready var wave_manager = $WaveManager
@onready var camera = $Camera2D
@onready var group_timer = $GroupTimer
@onready var wave_timer = $WaveTimer
@onready var tower_selection_ui = $TowerSelectionUI  # Add this node in the scene
@onready var tower_action_ui = $TowerActionUI        # Add this node in the scene
@onready var plots = get_tree().get_nodes_in_group("tower_plots")  # Group TowerPlot nodes

func _ready():
	load_wave_data("res://data/levels/level1.json")
	wave_manager.initialize(wave_data, group_timer, wave_timer, tilemap)
	camera.initialize(tilemap)
	# Connect plot and UI signals
	for plot in plots:
		plot.connect("plot_clicked", _on_plot_clicked)
	tower_selection_ui.connect("tower_selected", _on_tower_selected)
	tower_action_ui.connect("upgrade_tower", upgrade_tower)
	tower_action_ui.connect("sell_tower", sell_tower)
	print("Level initialized. Cash: ", cash, " Lives: ", lives)

func _on_plot_clicked(plot: Area2D):
	if not plot.is_occupied:
		tower_selection_ui.show_at_position(plot.position)
		print("Plot clicked at: ", plot.position)
	else:
		print("Plot already occupied!")

func _on_tower_selected(tower_scene: PackedScene):
	# Find the plot at the UI's position
	var plot = plots.filter(func(p): return p.position == tower_selection_ui.position)[0]
	if plot and not plot.is_occupied:
		var tower = tower_scene.instantiate()
		add_child(tower)  # Add to scene
		print("_on_tower_selected: ", tower.tower_id)
		var build_cost = get_build_cost(tower.tower_id)
		if cash >= build_cost:
			print("Before placement - Cash: ", cash, " Build cost: ", build_cost)
			cash -= build_cost
			tower.set_build_cost(build_cost)
			tower.position = plot.position
			plot.is_occupied = true
			plot.tower = tower
			tower.connect("tower_clicked", _on_tower_clicked)
			print("Placed ", tower.tower_id, " for ", build_cost, ". Cash: ", cash)
		else:
			print("Not enough cash! Need ", build_cost, ", have ", cash)
			tower.queue_free()
	else:
		print("No valid plot selected!")

func _on_tower_clicked(tower: Tower):
	tower_action_ui.show_for_tower(tower)
	print("Tower clicked: ", tower.tower_id, " at ", tower.position)

func get_build_cost(tower_id: String) -> int:
	print("get_build_cost: ", tower_id)
	match tower_id:
		"Archer": return 70
		"Baracks": return 70
		"Artillery": return 120
		"Mage": return 90
		_: return 100  # Default

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
	var plot = plots.filter(func(p): return p.tower == tower)[0]
	if plot:
		plot.is_occupied = false
		plot.tower = null
	tower.queue_free()  # Remove tower from scene
	print("Sold ", tower.tower_id, " for ", sell_value, ". Cash: ", cash)

func load_wave_data(path: String):
	var file = FileAccess.open(path, FileAccess.READ)
	if file:
		var json_text = file.get_as_text()
		wave_data = JSON.parse_string(json_text)
		file.close()
		lives = wave_data.get("lives", 20)
		cash = wave_data.get("cash", 1000)
		print("Wave data loaded: ", wave_data, " Lives: ", lives, "Cash: ", cash)
	else:
		push_error("Failed to load wave data from: " + path)

func enemy_reached_end(enemy: Enemy) -> void:
	lives -= int(enemy.penalty)
	print("Enemy reached end! Lives remaining: ", lives)
	if lives <= 0:
		print("Game Over! No lives remaining.")

func add_cash(cashToAdd: int):
	cash += cashToAdd
