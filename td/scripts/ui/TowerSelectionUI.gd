extends Control

signal tower_selected(tower_scene)

func _ready():
	visible = false
	$Panel/VBoxContainer/ArcherButton.connect("pressed", _on_archer_pressed)
	$Panel/VBoxContainer/BarackButton.connect("pressed", _on_barack_pressed)
	$Panel/VBoxContainer/ArtilleryButton.connect("pressed", _on_artillery_pressed)
	$Panel/VBoxContainer/MageButton.connect("pressed", _on_mage_pressed)

func show_at_position(pos: Vector2):
	position = pos
	visible = true

func _on_archer_pressed():
	emit_signal("tower_selected", preload("res://scenes/towers/Archer.tscn"))
	visible = false

func _on_barack_pressed():
	#emit_signal("tower_selected", preload("res://scenes/towers/Barack.tscn"))
	visible = false

func _on_artillery_pressed():
	#emit_signal("tower_selected", preload("res://scenes/towers/Artillery.tscn"))
	visible = false

func _on_mage_pressed():
	#emit_signal("tower_selected", preload("res://scenes/towers/Mage.tscn"))
	visible = false
