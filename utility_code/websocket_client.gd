
extends Node

class_name WebsocketClient

signal connected
signal disconnected(code : int,reason : String)
signal received(packet : String)

var _poll : Callable = _closed_poll

var _client : WebSocketPeer = WebSocketPeer.new()

func _ready():
	set_process(false)
	pass

func _process(_delta):
	_poll.call()

func connect_to_url(url : String) -> bool:
	var err := _client.connect_to_url(url)
	if err == OK:
		_poll = _connecting_poll
		set_process(true)
		return true
	return false

func send(message : String) -> bool:
	_client.poll()
	var err := _client.send_text(message)
	if err == OK:
		return true
	return false

func close(code: int = 1000, reason: String = ""):
	_client.close(code,reason)


func _connecting_poll():
	_client.poll()
	var state = _client.get_ready_state()
	if state == WebSocketPeer.STATE_OPEN:
		connected.emit()
		_poll = _open_poll
		while _client.get_available_packet_count():
			var packet := _client.get_packet()
			received.emit(packet.get_string_from_utf8())
	elif state == WebSocketPeer.STATE_CLOSED:
		var code := _client.get_close_code()
		var reason := _client.get_close_reason()
		disconnected.emit(code,reason)
		set_process(false)
		_poll = _closed_poll

func _open_poll():
	_client.poll()
	var state = _client.get_ready_state()
	if state == WebSocketPeer.STATE_OPEN:
		while _client.get_available_packet_count():
			var packet := _client.get_packet()
			received.emit(packet.get_string_from_utf8())
	elif state == WebSocketPeer.STATE_CLOSING:
		pass
	elif state == WebSocketPeer.STATE_CLOSED:
		var code = _client.get_close_code()
		var reason = _client.get_close_reason()
		disconnected.emit(code,reason)
		set_process(false)
		_poll = _closed_poll
	pass

func _closed_poll():
	pass
