extends Control

class_name DeckSetLabel

var deck_set : Deck

@onready var texture_rect = $TextureRect
@onready var faces := [$CardFace1, $CardFace2, $CardFace3, $CardFace4, $CardFace5, $CardFace6]
@onready var label = $Label

func initialize(deck : Deck):
	deck_set = deck
	for i in deck_set.cards.size():
		faces[i].initialize(Global.card_list.get_card_data(deck_set.cards[i]))
	label.text = deck_set.name
	var texture := texture_rect.texture as GradientTexture2D
	texture.gradient.colors[0] = deck_set.primary_color
	texture.gradient.colors[1] = deck_set.secondary_color


# Called when the node enters the scene tree for the first time.
func _ready():
	pass # Replace with function body.


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(_delta):
	pass
