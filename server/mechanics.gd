
class_name Mechanics


class CardData:
	var id : int
	var power : int
	var arrows : PackedInt32Array

	func _init(i : int,p : int,l : PackedInt32Array):
		id = i
		power = p
		arrows = l

class Player:
	var deck : Array[CardData]
	var hp : int
	var stock : Array[int] = []
	var hand : Array[int] = []
	var discard : Array[int] = []
	
	var rival : Player
	var number : int
	
	func _init(deck_list : Array[CardData],num : int):
		deck = deck_list.duplicate()
		hp = 20
		stock = [0,1,2,3,4,5]
		stock.shuffle()
		for i in 3:
			var c := stock.pop_back() as int
			hand.push_back(c)
		number = num

	func create_first_data() -> IGameServer.FirstData:
		var data := IGameServer.FirstData.new()
		data.my_deck.assign(deck.map(func(v : Mechanics.CardData):return v.id))
		data.my_hand = hand.duplicate()
		data.rival_deck_count = rival.deck.size()
		data.rival_hand_count = rival.hand.size()
		data.player_number = number
		return data

	func draw() -> Array[int]:
		var drawn_cards : Array[int] = []
		while hand.size() < 3:
			if stock.is_empty():
				if discard.is_empty():
					break
				else:
					discard.shuffle()
					stock = discard
					discard = []
			while hand.size() < 3 and not stock.is_empty():
				var card : int = stock.pop_back()
				hand.push_back(card)
				drawn_cards.push_back(card)
		return drawn_cards


class Square:
	var owner : Player = null
	var deck_index : int = -1
	var opened : bool = false

	func set_card(p : Player,i : int,o : bool):
		owner = p
		deck_index = i
		opened = o
	
	func reset():
		owner = null
		deck_index = -1
		opened = false
		

class Board:

	var player1 : Player
	var player2 : Player

	var field : Array[Square]

	var turn_count : int = 0
	var turn_player : Player = null
	var exturn_player : Player = null
	var draw_replay_index : int = -1


	func get_next_player() -> int:
		if exturn_player:
			return exturn_player.number
		return turn_player.number


	func initialize(p1_deck : Array[CardData],p2_deck : Array[CardData]) -> Array[IGameServer.FirstData]:
		player1 = null
		player2 = null
		field.assign(range(9).map(func(_i):return Square.new()))
		turn_count = 0
		turn_player = null
		exturn_player = null
		if p1_deck.size() != 6 or p2_deck.size() != 6:
			return []
		var p1_total : int = 0
		var p2_total : int = 0
		for i in 6:
			p1_total += p1_deck[i].power
			p2_total += p2_deck[i].power
		if p1_total < 15 or p2_total < 15:
			return []
		
		player1 = Player.new(p1_deck,1)
		player2 = Player.new(p2_deck,2)
		player1.rival = player2
		player2.rival = player1

		turn_count = 1
		turn_player = player1
		
		return [player1.create_first_data(),player2.create_first_data()]


	func play(player : Player,index : int,position : int) -> IGameServer.Result:
		assert(position >= 0 and position < field.size(),"out of range:position=%d" % position)
		if not player.hand.has(index):
			return null
			
		var result := IGameServer.Result.new()
		result.turn_count = turn_count
		result.player = player.number
		result.position = position
		result.play_card = player.deck[index].id
		result.closed_play_card = result.play_card
		var square := field[position]

		if exturn_player:
			if player != exturn_player:
				return null
			if square.owner:
				return null
			square.set_card(player,index,true)
			player.hand.erase(index)
			exturn_player = null
		else:
			if player != turn_player:
				return null
			if draw_replay_index != -1:
				if index != draw_replay_index:
					return null
				if square.owner:
					return null
				square.set_card(player,index,true)
				player.hand.erase(index)
				draw_replay_index = -1
			else:
				if square.owner == null:
					square.set_card(player,index,false)
					player.hand.erase(index)
					result.play_card = -1
				elif square.owner != player and not square.opened:
					var battle := IGameServer.Result.Battle.new()
					square.opened = true
					var play_card := player.deck[index]
					var square_card := square.owner.deck[square.deck_index]
					battle.card = square_card.id
					var square_power := maxi(square_card.power + get_total_arrows(position),0)
					if square_power > play_card.power:
						square.owner.discard.append(square.deck_index)
						square.set_card(player,index,true)
						player.hand.erase(index)
						battle.result = 1
					elif square_power < play_card.power:
						player.discard.append(index)
						player.hand.erase(index)
						battle.result = -1
					else:
						draw_replay_index = index
						battle.result = 0
						result.battle = battle
						result.next_player = player.number
						return result
					result.battle = battle
				else:
					return null
			turn_player = player.rival
		
		result.explosion = explode(player)
		
		if turn_player == null:
			result.next_player = 0
			return result
		
		if player.hand.is_empty() and player.discard.is_empty() and player.stock.is_empty():
			result.next_player = 0
			return result
		
		if exturn_player == null:
			turn_count += 1
			result.draw_cards = turn_player.draw()
			result.next_player = turn_player.number
		else:
			if exturn_player.hand.is_empty():
				result.draw_cards = exturn_player.draw()
			result.next_player = exturn_player.number
		return result


	func get_arrow(square : Square,direction : int) -> int:
		if not square.opened:
			return 0
		if square.owner == player1:
			return player1.deck[square.deck_index].arrows[direction]
		if square.owner == player2:
			return player2.deck[square.deck_index].arrows[(direction + 4) % 8]
		return 0
		
	func get_total_arrows(position : int) -> int:
		match position:
			0:
				return get_arrow(field[1],6) + get_arrow(field[3],0) + get_arrow(field[4],7)
			1:
				return get_arrow(field[0],2) + get_arrow(field[2],6) + get_arrow(field[3],1) + get_arrow(field[4],0) + get_arrow(field[5],7)
			2:
				return get_arrow(field[1],2) + get_arrow(field[4],1) + get_arrow(field[5],0)
			3:
				return get_arrow(field[0],4) + get_arrow(field[1],5) + get_arrow(field[4],6) + get_arrow(field[6],0) + get_arrow(field[7],7)
			4:
				return get_arrow(field[0],3) + get_arrow(field[1],4) + get_arrow(field[2],5) + get_arrow(field[3],2) \
						+ get_arrow(field[5],6) + get_arrow(field[6],1) + get_arrow(field[7],0) + get_arrow(field[8],7)
			5:
				return get_arrow(field[1],3) + get_arrow(field[2],4) + get_arrow(field[4],2) + get_arrow(field[7],1) + get_arrow(field[8],0)
			6:
				return get_arrow(field[3],4) + get_arrow(field[4],5) + get_arrow(field[7],6)
			7:
				return get_arrow(field[3],3) + get_arrow(field[4],4) + get_arrow(field[5],5) + get_arrow(field[6],2) + get_arrow(field[8],6)
			8:
				return get_arrow(field[4],3) + get_arrow(field[5],4) + get_arrow(field[7],2)

		return 0


	func explode(player : Player) -> IGameServer.Result.Explosion:
		const PATTERN := [
			[0,1,2],
			[3,4,5],
			[6,7,8],
			[0,3,6],
			[1,4,7],
			[2,5,8],
			[0,4,8],
			[2,4,6],
		]
		var exp_pattern := PATTERN.filter(
			func(p):
				return field[p[0]].owner == player and field[p[1]].owner == player and field[p[2]].owner == player
		)
		if exp_pattern.is_empty():
			#大爆発
			if field.all(func(s : Square):return s.owner != null):
				var explosion := IGameServer.Result.Explosion.new()
				var oexp := IGameServer.Result.Explosion.OtherExplosion.new()
				explosion.other = oexp
				for s in field:
					s.opened = true
				var player_total_power := 0
				var rival_total_power := 0
				for p in field.size():
					var square := field[p]
					if square.owner == player:
						player_total_power += player.deck[square.deck_index].power + get_total_arrows(p)
						explosion.positions.append(p)
						explosion.cards.append(player.deck[square.deck_index].id)
					elif square.owner == player.rival:
						rival_total_power += player.rival.deck[square.deck_index].power + get_total_arrows(p)
						oexp.positions.append(p)
						oexp.cards.append(player.rival.deck[square.deck_index].id)
				explosion.power = maxi(player_total_power,0)
				oexp.power = maxi(rival_total_power,0)
				if player_total_power >= rival_total_power:
					player.rival.hp -= player_total_power
					if player_total_power > rival_total_power:
						exturn_player = player.rival
					for s in field:
						if s.owner == player:
							s.owner.discard.append(s.deck_index)
							s.reset()
				if rival_total_power >= player_total_power:
					player.hp -= rival_total_power
					if rival_total_power > player_total_power:
						exturn_player = player
					for s in field:
						if s.owner == player.rival:
							s.owner.discard.append(s.deck_index)
							s.reset()
				if player.hp <= 0 or player.rival.hp <= 0:
					turn_player = null

				return explosion
			return null
		else:
			var explosion := IGameServer.Result.Explosion.new()
			var positions : Dictionary = {}
			for pat in exp_pattern:
				for p in pat:
					positions[p] = true
					field[p].opened = true
			
			var total_power := 0
			for p in positions:
				var square := field[p]
				total_power += square.owner.deck[square.deck_index].power + get_total_arrows(p)
				explosion.positions.append(p)
				explosion.cards.append(square.owner.deck[square.deck_index].id)
			explosion.power = total_power
			player.rival.hp -= maxi(total_power,0)
			if player.rival.hp > 0:
				exturn_player = player.rival
			else:
				turn_player = null
			
			for p in positions:
				var square := field[p]
				player.discard.append(square.deck_index)
				square.reset()
		
			return explosion
		
