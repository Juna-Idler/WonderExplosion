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

func initialize(my_card_list : Array[int],cpu_card_list : Array[int]) -> bool:
	var my_deck : Array[Mechanics.CardData] = []
	my_deck.assign(my_card_list.map(card_data_translate)) 
	var cpu_deck : Array[Mechanics.CardData] = []
	cpu_deck.assign(cpu_card_list.map(card_data_translate)) 
	
	first_data.my_deck = my_card_list
	first_data.rival_deck_count = cpu_card_list.size()
	if randi() & 1:
		if not board.initialize(my_deck,cpu_deck):
			return false
		player = board.player1
		cpu_player = board.player2
	else:
		if not board.initialize(cpu_deck,my_deck):
			return false
		player = board.player2
		cpu_player = board.player1
	first_data.my_hand = player.hand.duplicate()
	first_data.rival_hand_count = player.rival.hand.size()
	first_data.player_number = player.number
	
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
	


