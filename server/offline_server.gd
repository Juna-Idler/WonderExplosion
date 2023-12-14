extends IGameServer

class_name OfflineServer


var board := Mechanics.Board.new()
var first_data := FirstData.new()

var player : Mechanics.Player = null
var cpu_player : Mechanics.Player = null

var cpu_draw_replay := -1

func _init():
	pass

func card_data_translate(id : int) -> Mechanics.CardData:
	var data := Global.card_list.get_card_data(id)
	var card_data := Mechanics.CardData.new(data.id,data.power,data.arrows)
	return card_data

func initialize(my_name : String,my_card_list : Array[int],cpu_card_list : Array[int],my_colors : Array[Color],cpu_colors : Array[Color]) -> bool:
	var my_deck : Array[Mechanics.CardData] = []
	my_deck.assign(my_card_list.map(card_data_translate)) 
	var cpu_deck : Array[Mechanics.CardData] = []
	cpu_deck.assign(cpu_card_list.map(card_data_translate)) 
	
	if randi() & 1:
		var first := board.initialize(my_deck,cpu_deck)
		if first.is_empty():
			return false
		first_data = first[0]
		player = board.player1
		cpu_player = board.player2
	else:
		var first := board.initialize(cpu_deck,my_deck)
		if first.is_empty():
			return false
		first_data = first[1]
		player = board.player2
		cpu_player = board.player1
		
	first_data.my_name = my_name
	first_data.rival_name = "random cpu"
	first_data.my_colors = my_colors
	first_data.rival_colors = cpu_colors
	return true

func _send_ready_async() -> IGameServer.FirstData:
	return first_data


func _play_async(deck_index : int,position : int) -> Result:
	var result := board.play(player,deck_index,position)
	if result == null:
		return null
	
	if not result.draw_cards.is_empty() and result.next_player != player.number:
		result.draw_cards.assign(result.draw_cards.map(func(_v):return -1))
	print("play:%d pos:%d" % [deck_index,position])
	return result

func _wait_async() -> Result:
	var play : int = cpu_player.hand.pick_random()
	if cpu_draw_replay != -1:
		play = cpu_draw_replay
		cpu_draw_replay = -1
	var random_position := [0,1,2,3,4,5,6,7,8]
	random_position.shuffle()
	var result := board.play(cpu_player,play,random_position.pop_back())
	while result == null:
		assert(not random_position.is_empty())
		result = board.play(cpu_player,play,random_position.pop_back())
	if result.play_card == -1:
		result.closed_play_card = -1
	if not result.draw_cards.is_empty() and result.next_player != player.number:
		result.draw_cards.assign(result.draw_cards.map(func(_v):return -1))
	if result.battle and result.battle.result == 0:
		cpu_draw_replay = play
		
	print("wait:")
	return result
	


