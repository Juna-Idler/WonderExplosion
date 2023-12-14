extends Node



@onready var menu_layer = $MenuLayer
@onready var back_button = %BackButton
@onready var match_button = %MatchButton
@onready var deck_button = %DeckButton


@onready var build = %Build
@onready var build_layer = $BuildLayer

@onready var match_scene = $Match

@onready var deck_set_label = %DeckSetLabel
@onready var player_name_edit = %PlayerName

@onready var websocket_client : WebsocketClient = $WebsocketClient

var player_name : String = "no name"
var player_deck : Deck


var server : OnlineServer = null

# Called when the node enters the scene tree for the first time.
func _ready():
	player_deck = Global.settings.deck
	player_name = Global.settings.player_name
	player_name_edit.text = player_name
	
	deck_set_label.initialize(player_deck)
	match_scene.set_process(false)
	build.set_process(false)
	
	server = OnlineServer.new(websocket_client,"0.0")
	server.connected.connect(on_server_connected)
	
	websocket_client.connect_to_url("127.0.0.1:" + str(Global.PORT_NUMBER))

	player_deck = Deck.new("Default Deck",[1,2,3,4,5,6],Color.BLUE,Color.RED)



# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(_delta):
	pass

func on_server_connected(version_match : bool):
	if version_match:
		match_button.disabled = false


func _on_match_button_pressed():
	back_button.disabled = true
	match_button.disabled = true
	deck_button.disabled = true
	
	server.send_match(player_name,player_deck.cards,player_deck.primary_color,player_deck.secondary_color)
	await server.matched
	match_scene.set_process(true)
	match_scene.initialize(server)
	menu_layer.hide()
	back_button.disabled = false
	match_button.disabled = false
	deck_button.disabled = false



func _on_back_button_pressed():
	get_tree().change_scene_to_file("res://main.tscn")
	pass # Replace with function body.


func _on_build_back_button_pressed():
	build.set_process(false)
	build_layer.hide()
	menu_layer.show()


func _on_build_request_save(deck):
	player_deck = deck
	deck_set_label.initialize(deck)



func _on_match_requested_return():
	match_scene.set_process(false)
	menu_layer.show()


func _on_deck_button_pressed():
	build.set_process(true)
	build.initialize(player_deck)
	build_layer.show()
	menu_layer.hide()

