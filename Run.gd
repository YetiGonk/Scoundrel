extends Node2D

@onready var label = $PanelContainer/RichTextLabel
@onready var button = $PanelContainer/RunButton
@onready var main = get_tree().get_root().get_node("Main")

var is_hovered = false
var shake_text_bb = "[font_size=25][center][shake rate=15.0 level=15]RUN[/shake][/center]"
var still_text_bb = "[font_size=25][center]RUN[/center]"
var disabled_text_bb = "[font_size=25][center][color=#888888]RUN[/color][/center]"

var can_run = true
var ran_last_turn = false

func _ready() -> void:
	if label:
		label.text = still_text_bb
	
	# Connect the button's pressed signal
	button.connect("pressed", self._on_run_pressed)
	
	# Set initial state
	update_run_state()

func _process(_delta):
	update_run_state()

func update_run_state():
	if main == null:
		main = get_tree().get_root().get_node("Main")
		if main == null:
			return
	
	# Can only run when there are exactly 4 cards in the room
	# Can't run if we've already picked a card from this room (room size < 4)
	# Can't run if we ran last turn
	can_run = main.current_room.size() == 4 and not main.is_animating and not ran_last_turn
	
	button.disabled = !can_run
	
	if button.disabled:
		label.text = disabled_text_bb
		is_hovered = false
	elif is_hovered:
		label.text = shake_text_bb
	else:
		label.text = still_text_bb

func _input(event):
	if event is InputEventMouseMotion:
		if button.get_rect().has_point(get_viewport().get_mouse_position()):
			if not is_hovered and can_run:
				is_hovered = true
				label.text = shake_text_bb
		else:
			if is_hovered:
				is_hovered = false
				if can_run:
					label.text = still_text_bb

func _on_run_pressed():
	if can_run and main != null:
		main.run_from_room()
		ran_last_turn = true
