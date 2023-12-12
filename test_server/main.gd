extends Node


@export var port_number = Global.PORT_NUMBER

@onready var websocket_server : WebsocketServer = $WebsocketServer

var _version : String

class ClientData:
	var client_id : int
	var name : String
	var deck : PackedInt32Array
	var colors : Array[Color]
	var ready : bool
	
	func _init(id : int,n : String,d : PackedInt32Array,pc : Color,sc : Color):
		client_id = id
		name = n
		deck = d
		colors = [pc,sc]
		ready = false

class GameRoom:
	static var websocket_server : WebsocketServer
	var game : Mechanics.Board
	
	var player1 : ClientData
	var player2 : ClientData
	var starting_time : float

	func _init(p1 : ClientData,p2 : ClientData):
		game = Mechanics.Board.new()
		
		if randi() & 1:
			player1 = p1
			player2 = p2
		else:
			player1 = p2
			player2 = p1
		
		var deck1 : Array[Mechanics.CardData] = []
		var deck2 : Array[Mechanics.CardData] = []
		for i in player1.deck:
			var data := Global.card_list.get_card_data(i)
			deck1.append(Mechanics.CardData.new(data.id,data.power,data.arrows))
		for i in player2.deck:
			var data := Global.card_list.get_card_data(i)
			deck2.append(Mechanics.CardData.new(data.id,data.power,data.arrows))
		game.initialize(deck1,deck2)
		var p1_json := JSON.stringify({"type":"Matched","data":{}})
		var p2_json := JSON.stringify({"type":"Matched","data":{}})
		websocket_server.send(player1.client_id,p1_json)
		websocket_server.send(player2.client_id,p2_json)
	
	func receive_ready(client_id : int):
		if player1.client_id == client_id:
			player1.ready = true
		elif player2.client_id == client_id:
			player2.ready = true
		if player1.ready and player2.ready:
			var first1 := game.player1.create_first_data()
			var first2 := game.player2.create_first_data()
			first1.my_name = player1.name
			first1.rival_name = player2.name
			first2.my_name = player2.name
			first2.rival_name = player1.name
			first1.my_colors = player1.colors
			first1.rival_colors = player2.colors
			first2.my_colors = player2.colors
			first2.rival_colors = player1.colors
			websocket_server.send(player1.client_id,JSON.stringify({"type":"First","data":first1.serialize()}))
			websocket_server.send(player2.client_id,JSON.stringify({"type":"First","data":first2.serialize()}))
		
	func receive_play(client_id : int,index : int,position : int):
		var result : IGameServer.Result = null
		if client_id == player1.client_id:
			result = game.play(game.player1,index,position)
		elif client_id == player2.client_id:
			result = game.play(game.player2,index,position)
		
		if result == null:
			websocket_server.send(client_id,JSON.stringify({"type":"Result","data":{}}))
			return
		var draw := result.draw_cards
		var hidden_draw : Array[int] = []
		if not result.draw_cards.is_empty():
			hidden_draw.resize(draw.size())
			hidden_draw.fill(-1)

		if client_id == player1.client_id:
			result.draw_cards = hidden_draw if result.next_player != 1 else draw
			websocket_server.send(player1.client_id,JSON.stringify({"type":"Result","data":result.serialize()}))
			result.draw_cards = hidden_draw if result.next_player == 1 else draw
			result.closed_play_card = result.play_card
			websocket_server.send(player2.client_id,JSON.stringify({"type":"Result","data":result.serialize()}))
		elif client_id == player2.client_id:
			result.draw_cards = hidden_draw if result.next_player != 2 else draw
			websocket_server.send(player2.client_id,JSON.stringify({"type":"Result","data":result.serialize()}))
			result.draw_cards = hidden_draw if result.next_player == 2 else draw
			result.closed_play_card = result.play_card
			websocket_server.send(player1.client_id,JSON.stringify({"type":"Result","data":result.serialize()}))

	func receive_surrender(client_id : int):
		if player1.client_id == client_id:
			websocket_server.send(player1.client_id,JSON.stringify({"type":"End","data":{"msg":"you surrender"}}))
			websocket_server.send(player2.client_id,JSON.stringify({"type":"End","data":{"msg":"rival surrender"}}))
		elif player2.client_id == client_id:
			websocket_server.send(player2.client_id,JSON.stringify({"type":"End","data":{"msg":"you surrender"}}))
			websocket_server.send(player1.client_id,JSON.stringify({"type":"End","data":{"msg":"rival surrender"}}))

	func socket_disconnect(client_id : int):
		if player1.client_id == client_id:
			websocket_server.send(player2.client_id,JSON.stringify({"type":"End","data":{"msg":"rival disconnect"}}))
			pass
		elif player2.client_id == client_id:
			websocket_server.send(player1.client_id,JSON.stringify({"type":"End","data":{"msg":"rival disconnect"}}))
			pass
	
	func terminalize():
		websocket_server.send(player1.client_id,JSON.stringify({"type":"End","data":{"msg":"server error"}}))
		websocket_server.send(player2.client_id,JSON.stringify({"type":"End","data":{"msg":"server error"}}))


func _init():
	pass

var wait : ClientData
var match_users : Dictionary # client_id : GameRoom
var match_rooms : Dictionary # of GameRoom


# Called when the node enters the scene tree for the first time.
func _ready():
	websocket_server.listen(port_number,"127.0.0.1")
	GameRoom.websocket_server = websocket_server
	pass # Replace with function body.


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(_delta):
	pass


func _on_websocket_server_connected(_client_id : int):
	pass # Replace with function body.


func _on_websocket_server_disconnected(_client_id : int):
	pass # Replace with function body.


func _on_websocket_server_received(client_id : int, message : String):
	var dic = JSON.parse_string(message)
	var type : String = dic.get("type")
	var data : Dictionary = dic.get("data")
	
	print(type + ":" + str(client_id))

	match type:
		"Version":
			var _ver := data["version"] as String
			var send_dic := {
				"type":"Version",
				"data":{
					"version":_version
				}
			 }
			websocket_server.send(client_id,JSON.stringify(send_dic))

		"Match":
			var p_name := data["n"] as String
			var deck := data["d"] as PackedInt32Array
			var p_color := Color(data["c"][0] as String)
			var s_color := Color(data["c"][1] as String)
			
			var client := ClientData.new(client_id,p_name,deck,p_color,s_color)
			 
			if wait != null and websocket_server.client_opened(wait.client_id):
				print("Match:" + str(client_id) + "&" + str(wait.client_id))
				var room := GameRoom.new(wait,client)
				match_users[wait.client_id] = room
				match_users[client_id] = room
				wait = null
			else:
				wait = client

		"Ready":
			if match_users.has(client_id):
				(match_users[client_id] as GameRoom).receive_ready(client_id)
			
		"Play":
			var i := data["i"] as int
			var p := data["p"] as int
			if match_users.has(client_id):
				(match_users.get(client_id) as GameRoom).receive_play(client_id,i,p)
		
		"End":
			if match_users.has(client_id):
				var room := match_users.get(client_id) as GameRoom
				match_users.erase(room.player1.client_id)
				match_users.erase(room.player2.client_id)

				room.receive_surrender(client_id)
			elif wait != null and wait.client_id == client_id:
				wait = null
	
