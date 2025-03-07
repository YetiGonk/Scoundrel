# DiscardPile.gd
extends Node2D

var card_stack = []
var card_spacing = Vector2(0, -3)  # 2px y offset per card

func _ready():
	# Initialize the discard pile (empty at start)
	pass

# Add this to DiscardPile.gd
func add_card(card):
	# Remove the card from its current parent
	if card.get_parent():
		card.get_parent().remove_child(card)
	
	# Make sure the sprite texture is still loaded
	if card.suit and card.value:
		card.update_display(card.label, card.sprite)
	
	add_child(card)
	
	card.position = Vector2(925,400)
	
	# Apply stack offset
	var stack_pos = Vector2(0, card_stack.size() * card_spacing.y)
	card.position += stack_pos
	card.sprite.position = card.position
	
	# Set the z-index for proper layering
	card.z_index = card_stack.size()
	
	# Hide the label for cards in the discard pile
	if card.label:
		card.label.visible = false
	
	card_stack.append(card)

func get_card_count():
	return card_stack.size()
