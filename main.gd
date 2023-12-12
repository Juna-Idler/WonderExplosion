extends Node

@onready var title_layer = $TitleLayer
@onready var build_layer = $BuildLayer

@onready var match_scene = $Match
@onready var build = %Build
@onready var deck_set_label = %DeckSetLabel

var player_name : String = "no name"
var player_deck : Deck

var offline_server := OfflineServer.new()

# Called when the node enters the scene tree for the first time.
func _ready():
	player_deck = Deck.new("Default Deck",[1,2,3,4,5,6],Color.BLUE,Color.RED)
	deck_set_label.initialize(player_deck)
	match_scene.set_process(false)
	build.set_process(false)
	pass # Replace with function body.


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(_delta):
	pass



func _on_button_pressed():
	offline_server.initialize(player_name,player_deck.cards,player_deck.cards,
			[player_deck.primary_color,player_deck.secondary_color],[Color.BLACK,Color.WHITE])
	match_scene.set_process(true)
	match_scene.initialize(offline_server)
	title_layer.hide()


func _on_match_requested_return():
	match_scene.set_process(false)
	title_layer.show()


func _on_build_button_pressed():
	build.set_process(true)
	build.initialize(player_deck)
	build_layer.show()
	title_layer.hide()



func _on_build_back_button_pressed():
	build.set_process(false)
	build_layer.hide()
	title_layer.show()


func _on_build_request_save(deck):
	player_deck = deck
	deck_set_label.initialize(deck)



func _on_online_button_pressed():
	get_tree().change_scene_to_file("res://online/main.tscn")
