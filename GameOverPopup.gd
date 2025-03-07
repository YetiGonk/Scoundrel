extends Node2D

@onready var panel = $CanvasLayer/Panel
@onready var restart_button = $CanvasLayer/Panel/Button
@onready var result_label = $CanvasLayer/Panel/RichTextLabel

func set_result(victory: bool):
	if victory:
		result_label.text = "[font_size=30][center][wave amp=50.0 freq=5.0 connected=1]You Win![/wave][/center]"
	else:
		result_label.text = "[font_size=30][center][shake rate=20.0 level=5]You Are Dead...[/shake][/center]"

func _ready():
	var screen_size = get_viewport().get_visible_rect().size
	panel.position = (screen_size - panel.size) / 2

	restart_button.connect("pressed", self._on_restart_pressed)

func _on_restart_pressed():
	get_tree().reload_current_scene()
