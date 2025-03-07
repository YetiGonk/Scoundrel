extends Node2D

signal rules_acknowledged

@onready var rules_panel = $CanvasLayer/Panel
@onready var rules_label = $CanvasLayer/Panel/RulesLabel
@onready var continue_label = $CanvasLayer/Panel/ContinueLabel

var rules_text = """
[font_size=30][center]HOW TO PLAY[/center][/font_size]

[font_size=20][center]SCOUNDREL is a card-based dungeon crawler:

• Each 'dungeon room' consists of 4 cards from the deck
• Cards represent: 
  - Monsters (Clubs & Spades)
  - Weapons (Diamonds) 
  - Potions (Hearts)

• You start with 20 life points
• Defeat monsters with your bare hands (take full damage)
• Or defeat them with weapons (take partial damage)
• Weapons lose durability and can only battle weaker monsters each time.
• Heal with potions
• You can RUN from dangerous rooms (but not twice in a row)

• Win by surviving until the deck is empty
• Lose if your health reaches zero[/center]

[center][color=#888888]Press any key to continue...[/color][/center][/font_size]
"""

func _ready():
	var screen_size = get_viewport().get_visible_rect().size
	rules_panel.position = (screen_size - rules_panel.size) / 2
	
	rules_label.text = rules_text
	
	# Make the continue text pulse
	var tween = create_tween()
	tween.tween_property(continue_label, "modulate:a", 0.3, 1.0)
	tween.tween_property(continue_label, "modulate:a", 1.0, 1.0)
	tween.set_loops()

func _input(event):
	if event is InputEventKey and event.pressed:
		emit_signal("rules_acknowledged")
		queue_free()
