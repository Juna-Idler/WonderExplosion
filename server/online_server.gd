extends IGameServer

class_name OnlineServer

signal connected(version_match : bool)
signal disconnected

signal matched

signal received_first(data : IGameServer.FirstData)
signal received_result(data : IGameServer.Result)
signal received_end(msg : String)

var _socket : WebsocketClient

var _version : String
var _server_version : String

var result_stack : Array[IGameServer.Result]


func _init(socket : WebsocketClient,version : String):
	_version = version
	_socket = socket
	_socket.received.connect(on_websocket_received)
	_socket.connected.connect(on_websocket_connected)
	_socket.disconnected.connect(func(_code,_reason):disconnected.emit())


func on_websocket_connected():
	var dic := {
		"type":"Version",
		"data":{
			"version":_version
		}
	 }
	_socket.send(JSON.stringify(dic))

func send_match(player_name :String,deck :PackedInt32Array,p_color : Color,s_color : Color,key : String):
	var dic := {
		"type":"Match",
		"data":{
			"n":player_name,
			"d":deck,
			"c":[p_color.to_html(),s_color.to_html()],
			"k":key
		}
	}
	_socket.send(JSON.stringify(dic))

func send_match_cancel(key : String):
	var dic := {
		"type":"MatchCancel",
		"data":{
			"k":key
		}
	}
	_socket.send(JSON.stringify(dic))
	pass

func _send_ready_async() -> IGameServer.FirstData:
	result_stack = []
	var dic : Dictionary = {
		"type" : "Ready",
		"data" : {
		}
	}
	_socket.send(JSON.stringify(dic))
	var first : IGameServer.FirstData = await received_first
	return first


func _play_async(deck_index : int,position : int) -> Result:
	var dic : Dictionary = {
		"type" : "Play",
		"data" : {
			"i":deck_index,
			"p":position,
		}
	}
	_socket.send(JSON.stringify(dic))
	var result : IGameServer.Result = await received_result
	if result == null:
		return null
	result_stack.pop_front()
	return result


func _wait_async() -> Result:
	if result_stack.is_empty():
		if await received_result == null:
			return null
	var result : IGameServer.Result = result_stack.pop_front()
	return result
	

func send_surrender():
	var dic : Dictionary = {
		"type" : "End",
		"data" : {
		}
	}
	_socket.send(JSON.stringify(dic))

func on_websocket_received(message : String):
	var dic = JSON.parse_string(message) as Dictionary
	if dic == null:
		return
	var type : String = dic.get("type")
	var data : Dictionary = dic.get("data")
	if type == null or data == null:
		return
		
	match type:
		"Version":
			_server_version = data.get("version","")
			connected.emit(_version == _server_version)

		"Matched":
			matched.emit()

		"First":
			var first := IGameServer.FirstData.deserialize(data)
			received_first.emit(first)
		
		"Result":
			var result := IGameServer.Result.deserialize(data)
			if result:
				result_stack.push_back(result)
			received_result.emit(result)

		"End":
			var msg := data["msg"] as String
			received_end.emit(msg)
			
