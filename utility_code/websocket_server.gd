extends Node

class_name WebsocketServer


signal connected(client_id : int)
signal disconnected(client_id : int)
signal received(client_id : int,message : String)



var _server := TCPServer.new()

var _clients : Dictionary = {}
var _client_id_count : int = 1

var _connecting : Array[WebSocketPeer] = []



func listen(port_number : int,address : String = "*") -> void:
	_server.listen(port_number,address)

func stop() -> void:
	_server.stop()
	for c in _clients:
		var socket := _clients[c] as WebSocketPeer
		socket.close()
	for s in _connecting:
		s.close()


func close_client(client_id : int,code: int = 1000, reason: String = "") -> void:
	if not _clients.has(client_id):
		return
	(_clients[client_id] as WebSocketPeer).close(code,reason)

func send(client_id : int,message : String) -> bool:
	if not _clients.has(client_id):
		return false
	return (_clients[client_id] as WebSocketPeer).send_text(message) == OK


func get_clients() -> Dictionary:
	return _clients

func client_opened(client_id : int) -> bool:
	if not _clients.has(client_id):
		return false
	return (_clients[client_id] as WebSocketPeer).get_ready_state() == WebSocketPeer.STATE_OPEN

func _ready():
	pass # Replace with function body.


func _process(_delta):
	while _server.is_connection_available():
		var peer = _server.take_connection()
		var socket = WebSocketPeer.new()
		var _err = socket.accept_stream(peer)
		_connecting.append(socket)

	if not _connecting.is_empty():
		var next_connecting : Array[WebSocketPeer] = []
		for s in _connecting:
			s.poll()
			var state := s.get_ready_state()
			match state:
				WebSocketPeer.STATE_OPEN:
					_clients[_client_id_count] = s
					connected.emit(_client_id_count)
					_client_id_count += 1
				WebSocketPeer.STATE_CLOSING:
					pass
				WebSocketPeer.STATE_CLOSED:
					pass
				WebSocketPeer.STATE_CONNECTING:
					next_connecting.append(s)
					pass
		_connecting = next_connecting
	
	var removed : Array[int] = []
	for c in _clients:
		var socket := _clients[c] as WebSocketPeer
		socket.poll()
		var state := socket.get_ready_state()
		match state:
			WebSocketPeer.STATE_OPEN:
				var count = socket.get_available_packet_count()
				while count > 0:
					var packet = socket.get_packet()
					var message := packet.get_string_from_utf8()
					received.emit(c,message)
					count = socket.get_available_packet_count()
			WebSocketPeer.STATE_CLOSING:
				pass
			WebSocketPeer.STATE_CLOSED:
				disconnected.emit(c)
				removed.append(c)
			WebSocketPeer.STATE_CONNECTING:
				pass
	for c in removed:
		_clients.erase(c)


