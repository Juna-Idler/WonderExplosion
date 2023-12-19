extends Node


@onready var match_scene = $Match

@onready var match_ui_layer = $MatchUILayer
@onready var result_display = %ResultDisplay
@onready var result_message = %ResultMessage
@onready var settings = %Settings


@onready var build = %Build
@onready var build_layer = $BuildLayer


@onready var menu_layer = $MenuLayer
@onready var back_button = %BackButton
@onready var match_button = %MatchButton
@onready var deck_button = %DeckButton

@onready var keyword = %Keyword

@onready var deck_set_label = %DeckSetLabel
@onready var player_name_edit = %PlayerName

@onready var message = %Message
@onready var message_label = %MessageLabel
@onready var message_button = %MessageButton

enum MessageType {
	NO_MESSAGE,
	DISCONNECT,
	MATCH_WAITING,
	MATCH_CANCEL,
}
var message_type : MessageType = MessageType.NO_MESSAGE


@onready var websocket_client : WebsocketClient = $WebsocketClient

var player_name : String = "no name"
var player_deck : Deck


var server : OnlineServer = null

var waiter : SignalWaiter.One = null


# Called when the node enters the scene tree for the first time.
func _ready():
	match_ui_layer.hide()
	build_layer.hide()
	menu_layer.show()
	
	player_deck = Global.settings.deck
	player_name = Global.settings.player_name
	player_name_edit.text = player_name
	
	deck_set_label.initialize(player_deck)
	match_scene.set_process(false)
	build.set_process(false)
	message.hide()
	
	server = OnlineServer.new(websocket_client,"0.0")
	server.connected.connect(on_server_connected)
	server.disconnected.connect(on_server_disconnected)
	server.received_end.connect(on_server_received_end)
	
	if not websocket_client.connect_to_url(Global.settings.online_url):
		set_message(MessageType.DISCONNECT)



# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(_delta):
	pass

func set_message(type : MessageType):
	message_type = type
	match type:
		MessageType.DISCONNECT:
			message_label.text = "サーバとの接続が切断されました"
			message_button.text = "タイトルに戻る"
		MessageType.MATCH_WAITING:
			message_label.text = "対戦相手を待っています"
			message_button.text = "キャンセル"
		MessageType.MATCH_CANCEL:
			message_label.text = "対戦待ちをキャンセルしました"
			message_button.text = "戻る"
	message.show()


func on_server_connected(version_match : bool):
	if version_match:
		match_button.disabled = false

func on_server_disconnected():
	set_message(MessageType.DISCONNECT)

func on_server_received_end(msg : String):
	match_scene.end()
	result_message.text = msg
	result_display.show()
	settings.hide()


func _on_match_button_pressed():
	set_message(MessageType.MATCH_WAITING)
	server.send_match(player_name,player_deck.cards,player_deck.primary_color,player_deck.secondary_color,keyword.text)
	waiter = SignalWaiter.One.new(server.matched)
	var wait = await waiter.wait()
	if wait.is_empty():
		set_message(MessageType.MATCH_CANCEL)
		waiter = null
		return
	waiter = null
	match_scene.set_process(true)
	match_scene.initialize(server)
	match_ui_layer.show()
	settings.hide()
	result_display.hide()
	menu_layer.hide()
	message.hide()


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


func _on_deck_button_pressed():
	build.set_process(true)
	build.initialize(player_deck)
	build_layer.show()
	menu_layer.hide()


func _on_message_button_pressed():
	match message_type:
		MessageType.DISCONNECT:
			get_tree().change_scene_to_file("res://main.tscn")
		MessageType.MATCH_WAITING:
			server.send_match_cancel(keyword.text)
			waiter.cancel()
		MessageType.MATCH_CANCEL:
			message.hide()
	pass # Replace with function body.


func _on_match_finished(player_life, rival_life):
	var result := int(rival_life <= 0) - int(player_life <= 0)
	if result > 0:
		result_message.text = "YOU WIN"
	elif result < 0:
		result_message.text = "YOU LOSE"
	else:
		result_message.text = "DRAW"
	result_display.show()

func _on_return_button_pressed():
	match_ui_layer.hide()
	result_display.hide()
	match_scene.set_process(false)
	menu_layer.show()



func _on_settings_button_pressed():
	settings.show()

func _on_close_settings_button_pressed():
	settings.hide()

func _on_surrender_button_pressed():
	server.send_surrender()
