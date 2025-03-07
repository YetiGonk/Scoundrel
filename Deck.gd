# Deck.gd
extends Node2D

var card_stack = []
var card_spacing = Vector2(0, 3)

func initialise_deck_visuals():
	card_stack.clear()

	var main = get_tree().get_root().get_node("Main")
	if main:
		var deck_size = main.deck_array.size()
		print(deck_size)
		for i in range(deck_size):
			var card_back = Sprite2D.new()
			card_back.texture = load("res://cards/card_blue.png")
			card_back.z_index = i
			add_child(card_back)
			card_back.centered = false
			card_back.position += Vector2(0, i * card_spacing.y)
			card_stack.append(card_back)

func draw_card():
	if card_stack.size() > 0:
		var card = card_stack.pop_back()
		return card
	return null

func update_stack():
	for i in range(card_stack.size()):
		card_stack[i].position = Vector2(0, i * card_spacing.y)
