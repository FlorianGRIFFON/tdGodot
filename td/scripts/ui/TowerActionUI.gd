extends Control

signal upgrade_tower(tower, next_level)
signal sell_tower(tower)

var current_tower: Tower = null

@onready var upgrade_path_a = $Panel/VBoxContainer/UpgradeButtonA
@onready var upgrade_path_b = $Panel/VBoxContainer/UpgradeButtonB
@onready var sell_button = $Panel/VBoxContainer/SellButton
@onready var cost_label_a = $Panel/VBoxContainer/CostLabelA
@onready var cost_label_b = $Panel/VBoxContainer/CostLabelB

func _ready():
	visible = false

func show_for_tower(tower: Tower):
	current_tower = tower
	position = tower.position + Vector2(20, -50)
	
	# Set button visibility and costs based on upgrade level
	if tower.upgrade_level < 2:
		upgrade_path_a.visible = true
		upgrade_path_a.text = "Upgrade"
		cost_label_a.text = "Cost: " + str(tower.get_cost())
		upgrade_path_b.visible = false
		cost_label_b.visible = false
	elif tower.upgrade_level == 2:
		upgrade_path_a.visible = true
		upgrade_path_a.text = "Path A"
		cost_label_a.text = "Cost: " + str(tower.get_cost())  # Level 3 cost
		upgrade_path_b.visible = true
		upgrade_path_b.text = "Path B"
		cost_label_b.visible = true
		cost_label_b.text = "Cost: " + str(tower.get_cost())  # Level 4 cost (same for now)
	else:  # Levels 3 or 4 (maxed)
		upgrade_path_a.visible = false
		upgrade_path_b.visible = false
		cost_label_a.text = "Max Level"
		cost_label_b.visible = false
	
	sell_button.visible = true
	visible = true
	print("TowerActionUI shown at: ", position, " for ", tower.tower_id, " level ", tower.upgrade_level)

func _on_upgrade_pressed():
	if current_tower:
		emit_signal("upgrade_tower", current_tower)
	visible = false


func _on_upgrade_button_a_pressed() -> void:
	if current_tower:
		var next_level = 3 if current_tower.upgrade_level == 2 else -1
		emit_signal("upgrade_tower", current_tower, next_level)
	visible = false


func _on_upgrade_button_b_pressed() -> void:
	if current_tower:
		emit_signal("upgrade_tower", current_tower, 4)  # Always 4 for Path B
	visible = false


func _on_sell_button_pressed() -> void:
	if current_tower:
		emit_signal("sell_tower", current_tower)
	visible = false
