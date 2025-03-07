extends Node2D

@onready var sprite = get_child(0).get_child(0)
@onready var label = get_child(0).get_child(-1)

var suit: String
var value: int
var type: String

var width: int = 132
var height: int = 180

var original_width: float = 1.0
var animation_phase: String = ""
var original_texture: Texture
var halfway_point: Vector2

var is_hovered: bool = false

func _ready():
	update_display(label, sprite)
	label.visible = false

func _input(event):
	if event is InputEventMouseMotion:
		var local_pos = sprite.get_global_transform_with_canvas().affine_inverse() * event.position
		var main = get_tree().get_root().get_node("Main")
		if self in main.current_room:
			if sprite.get_rect().has_point(local_pos):
				if not is_hovered:
					is_hovered = true
					label.visible = true
			else:
				if is_hovered:
					is_hovered = false
					label.visible = false

func initialize(card_suit: String, card_value: int):
	suit = card_suit
	value = card_value
	determine_type()
	update_display(label, sprite)

func determine_type():
	if suit == "spades" or suit == "clubs":
		type = "monster"
	elif suit == "diamonds":
		type = "weapon"
	elif suit == "hearts":
		type = "potion"

func update_display(label: Label, sprite: Sprite2D):
	if label:
		label.text = str(type).capitalize()

	if sprite and suit and value:
		sprite.texture = load("res://cards/%s_%d.png" % [suit, value])
