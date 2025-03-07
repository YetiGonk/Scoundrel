# Main.gd
extends Node2D

@onready var health_label = $Health
@onready var deck = $Deck
@onready var discard_pile = $DiscardPile
@onready var game_over_popup = preload("res://GameOverPopup.tscn")
@onready var game_menu = preload("res://GameMenu.tscn")
@onready var rules_overlay = preload("res://RulesOverlay.tscn")

var deck_array: Array = []
var current_room: Array = []
var deferred_rooms: Array = []
var life_points: int = 20
var max_life: int = 20
var equipped_weapon: Dictionary = {}
var defeated_monsters: Array = []
var z_index_counter: int = 0

var is_animating = false
var animation_speed = 400  # pixels per second
var cards_to_animate = []
var target_positions = []

var weapon_position = Vector2(486, 308)
var monster_start_offset = Vector2(150, 0)
var monster_stack_offset = Vector2(30, 10)

var run_button_ref = null
var is_running = false
var game_started = false

func _ready():
	# Create the main menu first
	var menu_instance = game_menu.instantiate()
	add_child(menu_instance)
	menu_instance.connect("start_game", self._on_game_start)
	
	# Initialize game data but don't start yet
	initialise_deck()
	deck.initialise_deck_visuals()
	discard_pile.position = Vector2(925, 400)
	
	# Hide game elements until game starts
	health_label.visible = false
	deck.visible = false
	discard_pile.visible = false
	
	# Hide RunButton if it exists
	var run_button = get_node_or_null("RunButton")
	if run_button:
		run_button.visible = false

func _on_game_start():
	# Show game elements
	health_label.visible = true
	deck.visible = true
	discard_pile.visible = true
	
	# Show RunButton if it exists
	var run_button = get_node_or_null("RunButton")
	if run_button:
		run_button.visible = true
	
	# Show rules overlay
	var rules_instance = rules_overlay.instantiate()
	add_child(rules_instance)
	rules_instance.connect("rules_acknowledged", self._on_rules_acknowledged)

func _on_rules_acknowledged():
	# Start the actual game
	game_started = true
	start_new_room()

func _input(event):
	if not game_started:
		return
		
	if event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT and not is_animating and life_points > 0:
		for card in current_room:
			var local_pos = card.sprite.get_global_transform_with_canvas().affine_inverse() * event.position
			if card.sprite.get_rect().has_point(local_pos):
				resolve_card(card)
				break

func _process(delta):
	if is_animating and cards_to_animate.size() > 0:
		var all_arrived = true
		var distance_to_travel = animation_speed * delta
		
		for i in range(cards_to_animate.size()):
			var card = cards_to_animate[i]
			var target = target_positions[i]
			
			# Calculate direction and distance
			var direction = (target - card.position).normalized()
			var distance = card.position.distance_to(target)
			
			if distance > 5:  # Not arrived yet
				all_arrived = false
				
				# Move the card
				if distance < distance_to_travel:
					card.position = target
				else:
					card.position += direction * distance_to_travel
				
				# Update sprite position to match card position
				card.sprite.position = card.position
				
				# Handle width animation and texture change for running cards
				if is_running:
					# First half of animation - shrink width to 0
					if card.animation_phase == "shrink":
						# Calculate how far along the shrinking phase we are (1.0 to 0.0)
						var start_distance = card.halfway_point.distance_to(card.position)
						var total_first_half = card.halfway_point.distance_to(card.position) * 2
						var shrink_progress = start_distance / total_first_half
						
						# Apply scale based on progress (1.0 to 0.0)
						card.sprite.scale.x = card.original_width * shrink_progress
						
						# If we've passed or reached the halfway point, change texture and start expanding
						if card.position.distance_to(target) <= card.halfway_point.distance_to(target):
							card.sprite.texture = load("res://cards/card_blue.png")
							card.sprite.scale.x = 0
							card.animation_phase = "expand"
					
					# Second half of animation - expand width with new texture
					elif card.animation_phase == "expand":
						# Calculate expansion progress (0.0 to 1.0)
						var current_distance = card.position.distance_to(target)
						var total_second_half = card.halfway_point.distance_to(target)
						var expand_progress = 1.0 - (current_distance / total_second_half)
						
						# Apply scale based on progress (0.0 to 1.0)
						card.sprite.scale.x = card.original_width * expand_progress
			else:
				# Final position adjustment
				card.position = target
				card.sprite.position = target
				
				if card not in deck_array:
					deck_array.append(card)
				
				# Reset scale if running
				if is_running:
					card.sprite.scale.x = card.original_width
				
				# Position the label correctly if not running
				if not is_running:
					card.label.position = card.position + Vector2(card.width/2-card.label.size.x/2, -30)

		# If all cards have arrived at their destinations
		if all_arrived:
			is_animating = false
			cards_to_animate.clear()
			target_positions.clear()
			
			if is_running:
				_on_animation_completed()
			else:
				# Make sure all cards are positioned correctly
				position_room_cards()

func initialise_deck():
	var suits = ["spades", "clubs", "diamonds", "hearts"]
	for suit in suits:
		for value in range(2, 15):  # 2-14 (Ace is 14)
			if (suit == "hearts" or suit == "diamonds") and value >= 11:
				continue
			deck_array.append({"suit": suit, "value": value})
	deck_array.shuffle()

func start_new_room(last_card = null):
	if deck_array.size() < 4:
		end_game(true)
		return

	if life_points == 0:
		return

	if is_animating:
		return  # Don't start a new room if animations are still running
	
	current_room.clear()
	cards_to_animate.clear()
	target_positions.clear()
	
	# Keep the last card if provided
	if last_card:
		current_room.append(last_card)
	
	# Calculate how many cards to draw
	var cards_to_draw = 4 - current_room.size()
	
	# Setup animation
	is_animating = true
	
	# Calculate initial and target positions for each card
	var start_x = 300
	
	for i in range(cards_to_draw):
		if deck_array.size() > 0:
			var card_data = deck_array.pop_front()
			var card = load("res://Card.tscn").instantiate()
			card.initialize(card_data["suit"], card_data["value"])

			# Get a card back from the deck visual
			var card_back = deck.draw_card()
			if card_back:
				# Set the initial position to the deck's position
				card.position = deck.global_position + card_back.position
				card_back.queue_free()  # Remove the card back
			else:
				card.position = deck.global_position

			# Calculate the target position in the room
			var idx = current_room.size()
			# Use a default card width if the texture isn't loaded yet
			var card_width = 132  # This matches the width in your Card.gd
			if card.sprite and card.sprite.texture:
				card_width = card.sprite.texture.get_width()
			var target_pos = Vector2(start_x + idx * (card_width + 30), 75)

			current_room.append(card)
			add_child(card)
			
			# Add to animation queue
			cards_to_animate.append(card)
			target_positions.append(target_pos)

			# Set z-index for proper layering
			card.z_index = z_index_counter
			z_index_counter += 1

			# Hide the label until animation is complete
			card.label.visible = false

	# Update the deck visuals
	deck.update_stack()
	
	# If there are no animations to play, position cards immediately
	if cards_to_animate.is_empty():
		is_animating = false
		position_room_cards()

func position_room_cards():
	if is_animating:
		return  # Don't reposition if animations are running
		
	var start_x = 300
	
	for i in range(current_room.size()):
		var card = current_room[i]
		var card_position = Vector2(start_x + i * (card.sprite.texture.get_width() + 30), 75)
		card.position = card_position
		card.sprite.position = card_position
		card.label.position = card_position + Vector2(card.width/2-card.label.size.x/2, -30)

		card.z_index = z_index_counter
		z_index_counter += 1

		card.label.text = str(card.type).capitalize()

func resolve_card(card):
	# Reset the ran_last_turn flag in the run button
	var run_button = get_node_or_null("RunButton")
	if run_button:
		run_button.ran_last_turn = false
	
	# Process card effects based on type
	if card.type == "monster":
		attack_monster(card)
	elif card.type == "weapon":
		equip_weapon(card)
	elif card.type == "potion":
		use_potion(card)
	
	# Important: Remove the card from the current_room array
	current_room.erase(card)
	
	# Reposition remaining cards
	position_room_cards()
	
	# Start a new room if only 1 card is left
	if current_room.size() == 1:
		start_new_room(current_room[0])
		
	# Debug
	debug_room_cards()

func attack_monster(monster):
	if equipped_weapon:
		var damage
		if defeated_monsters.size() > 0:
			if defeated_monsters[defeated_monsters.size()-1].value > monster.value:
				damage = monster.value - equipped_weapon["value"]
				if damage < 0:
					damage = 0
				if damage > life_points:
					damage = life_points
				life_points -= damage
				monster.z_index = z_index_counter
				z_index_counter += 1
				defeated_monsters.append(monster)
				position_monster_stack()
				check_game_over()
			else:
				if monster.value > life_points:
					life_points = 0
				else:
					life_points -= monster.value
				check_game_over()
				health_label.text = str(life_points)
				discard_pile.add_card(monster)
		else:
			if monster.value <= equipped_weapon["value"]:
				monster.z_index = z_index_counter
				z_index_counter += 1
				defeated_monsters.append(monster)
				position_monster_stack()
			else:
				damage = monster.value - equipped_weapon["value"]
				if damage < 0:
					damage = 0
				if damage > life_points:
					damage = life_points
				life_points -= damage
				monster.z_index = z_index_counter
				z_index_counter += 1
				defeated_monsters.append(monster)
				position_monster_stack()
				
			health_label.text = str(life_points)
			check_game_over()
	else:
		if monster.value > life_points:
			life_points = 0
		else:
			life_points -= monster.value
		health_label.text = str(life_points)
		discard_pile.add_card(monster)
		check_game_over()

func position_monster_stack():
	var total_width = monster_stack_offset.x * (defeated_monsters.size() - 1)
	var start_x = weapon_position.x + monster_start_offset.x - total_width / 2

	var weapon_adjustment = Vector2(-total_width / 2, 0)
	equipped_weapon["node"].position = weapon_position + weapon_adjustment
	equipped_weapon["node"].sprite.position = weapon_position + weapon_adjustment

	var last_z = 0

	for i in range(defeated_monsters.size()):
		var monster = defeated_monsters[i]
		var stack_position = Vector2(
			start_x + i * monster_stack_offset.x,
			weapon_position.y + monster_stack_offset.y * i
		)

		monster.position = stack_position
		monster.sprite.position = stack_position
		monster.sprite.z_index = last_z
		last_z += 1

func equip_weapon(weapon):
	clear_weapon_and_monsters()
	
	equipped_weapon = {
		"suit": weapon.suit, 
		"value": weapon.value,
		"node": weapon
	}

	weapon.z_index = z_index_counter
	z_index_counter += 1
	
	equipped_weapon["node"].position = weapon_position
	equipped_weapon["node"].sprite.position = weapon_position
	equipped_weapon["node"].label.text = ""

func clear_weapon_and_monsters():
	for monster in defeated_monsters:
		discard_pile.add_card(monster)
	defeated_monsters.clear()
	
	if equipped_weapon.has("node"):
		discard_pile.add_card(equipped_weapon["node"])
		equipped_weapon.clear()

func use_potion(potion):
	# Update health points
	life_points = min(life_points + potion.value, max_life)
	health_label.text = str(life_points)
	
	# Add to discard pile - this should handle removing it from its current parent
	discard_pile.add_card(potion)

func run_from_room():
	if current_room.size() != 4 or is_animating:
		return
	
	is_running = true
	
	# Start animation to move cards to the bottom of the deck
	is_animating = true
	cards_to_animate.clear()
	target_positions.clear()
	
	# For each card in the room
	for card in current_room:
		# Store original width for reference
		card.original_width = card.sprite.scale.x
		card.animation_phase = "shrink"  # Track animation phase
		card.original_texture = card.sprite.texture  # Store original texture
		card.halfway_point = deck.global_position + (card.position - deck.global_position) / 2
		
		# Set z_index lower than the deck to appear behind it
		card.z_index = -10 - current_room.find(card)  # Different z_index for each card
		
		# Animate moving it to the deck position
		cards_to_animate.append(card)
		target_positions.append(deck.global_position)
		
		# Add the card data back to the bottom of the deck
		var card_data = {"suit": card.suit, "value": card.value}
		deck_array.push_back(card_data)

func _on_animation_completed():
	# This is called after the animation is complete
	if is_running:
		# Clean up the animated cards
		for card in current_room:
			remove_child(card)
			card.queue_free()
		
		current_room.clear()
		is_running = false
		
		# Update the deck visuals
		deck.initialise_deck_visuals()
		
		# Start a new room
		start_new_room()
	
		# Get the run button and set ran_last_turn flag
		var run_button = get_node_or_null("RunButton")
		if run_button:
			run_button.ran_last_turn = true

func debug_room_cards():
	print("Current room has ", current_room.size(), " cards:")
	for i in range(current_room.size()):
		var card = current_room[i]
		print("  Card ", i, ": ", card.suit, " ", card.value, " (", card.type, ") - Parent: ", card.get_parent().name)
	
	print("Card children of Main:")
	for child in get_children():
		if child is Node2D and child.has_method("initialize") and "suit" in child:
			print("  Card: ", child.suit, " ", child.value, " (", child.type, ") - In current_room: ", current_room.has(child))

func check_game_over():
	if life_points <= 0:
		end_game(false)
	elif deck_array.is_empty() and deferred_rooms.is_empty():
		end_game(true)

func end_game(victory: bool):
	var popup_instance = game_over_popup.instantiate()
	popup_instance.position = get_viewport_rect().size / 2
	add_child(popup_instance)
	popup_instance.set_result(victory)
