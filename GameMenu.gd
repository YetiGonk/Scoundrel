extends Node2D

signal start_game

@onready var start_button = $CanvasLayer/Panel/StartButton
@onready var title_label = $CanvasLayer/Panel/TitleLabel

func _ready():
	var screen_size = get_viewport().get_visible_rect().size
	$CanvasLayer/Panel.position = (screen_size - $CanvasLayer/Panel.size) / 2
	
	start_button.connect("pressed", self._on_start_pressed)
	
	# Set title with fancy rich text
	title_label.text = "[font_size=50][center][wave amp=50.0 freq=5.0 connected=1]SCOUNDREL[/wave][/center]"

func _on_start_pressed():
	emit_signal("start_game")
	queue_free()
