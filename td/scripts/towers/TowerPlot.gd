extends Area2D

signal plot_clicked(plot)

var is_occupied: bool = false
var tower: Node = null

func _ready():
	connect("input_event", _on_input_event)

func _on_input_event(_viewport, event, _shape_idx):
	if event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
		if not is_occupied:
			emit_signal("plot_clicked", self)
