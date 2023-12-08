
class_name Mechanics


class CardData:
	var id : int
	var spell : String
	var power : int
	var leaks : PackedInt32Array


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

class Square:
	var owner : Player = null
	var deck_index : int = -1
	var opened : bool = false
	
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


	func get_winner() -> int:
		if turn_player or player1 == null or player2 == null:
			return 0
		if player1.hp <= 0:
			return 2
		if player2.hp <= 0:
			return 1
		return 0

	func get_next_player() -> int:
		if exturn_player:
			return exturn_player.number
		return turn_player.number


	func initialize(p1_deck : Array[CardData],p2_deck : Array[CardData]) -> bool:
		player1 = null
		player2 = null
		field.assign(range(9).map(func(_i):return Square.new()))
		turn_count = 0
		turn_player = null
		exturn_player = null
		if p1_deck.size() != 6 or p2_deck.size() != 6:
			return false
		var p1_total : int = 0
		var p2_total : int = 0
		for i in 6:
			p1_total += p1_deck[i].power
			p2_total += p2_deck[i].power
		if p1_total < 15 or p2_total < 15:
			return false
		
		player1 = Player.new(p1_deck,1)
		player2 = Player.new(p2_deck,2)
		player1.rival = player2
		player2.rival = player1

		turn_count = 1
		turn_player = player1
		return true


	func play(player : Player,index : int,point : int) -> IGameServer.Result:
		assert(point >= 0 and point < field.size(),"out of range:point=%d" % point)
		if not player.hand.has(index):
			return null
			
		var result := IGameServer.Result.new()
		result.turn_count = turn_count
		result.player = player.number
		result.position = point
		result.play_card = player.deck[index].id
		result.closed_play_card = result.play_card
		var square := field[point]

		if exturn_player:
			if player != exturn_player:
				return null
			if square.owner:
				return null
			square.owner = player
			square.deck_index = index
			square.opened = true
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
				square.owner = player
				square.deck_index = index
				square.opened = true
				player.hand.erase(index)
				draw_replay_index = -1
			else:
				if square.owner == null:
					square.owner = player
					square.deck_index = index
					square.opened = false
					player.hand.erase(index)
					result.play_card = -1
				elif square.owner != player and not square.opened:
					var battle := IGameServer.Result.Battle.new()
					square.opened = true
					var play_card := player.deck[index]
					var square_card := square.owner.deck[square.deck_index]
					battle.card = square_card.id
					var square_power := maxi(square_card.power + get_total_leaks(point),0)
					if square_power > play_card.power:
						square.owner.discard.append(square.deck_index)
						square.owner = player
						square.deck_index = index
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
			var draw : Array[int] = []
			while turn_player.hand.size() < 3:
				if turn_player.stock.is_empty():
					if turn_player.discard.is_empty():
						break
					else:
						turn_player.discard.shuffle()
						turn_player.stock = turn_player.discard
						turn_player.discard = []
				while turn_player.hand.size() < 3 and not turn_player.stock.is_empty():
					var card : int = turn_player.stock.pop_back()
					turn_player.hand.push_back(card)
					draw.push_back(card)
			result.next_player = turn_player.number
			result.draw_cards = draw
		else:
			if exturn_player.hand.is_empty():
				var draw : Array[int] = []
				while exturn_player.hand.size() < 3:
					if exturn_player.stock.is_empty():
						if exturn_player.discard.is_empty():
							break
						else:
							exturn_player.discard.shuffle()
							exturn_player.stock = exturn_player.discard
							exturn_player.discard = []
					while exturn_player.hand.size() < 3 and not exturn_player.stock.is_empty():
						var card : int = exturn_player.stock.pop_back()
						exturn_player.hand.push_back(card)
						draw.push_back(card)
				result.draw_cards = draw
			
			result.next_player = exturn_player.number
		return result


	func get_leak(square : Square,direction : int) -> int:
		if not square.opened:
			return 0
		if square.owner == player1:
			return player1.deck[square.deck_index].leaks[direction]
		if square.owner == player2:
			return player2.deck[square.deck_index].leaks[(direction + 4) % 8]
		return 0
		
	func get_total_leaks(point : int) -> int:
		match point:
			0:
				return get_leak(field[1],6) + get_leak(field[3],0) + get_leak(field[4],7)
			1:
				return get_leak(field[0],2) + get_leak(field[2],6) + get_leak(field[3],1) + get_leak(field[4],0) + get_leak(field[5],7)
			2:
				return get_leak(field[1],2) + get_leak(field[4],1) + get_leak(field[5],0)
			3:
				return get_leak(field[0],4) + get_leak(field[1],5) + get_leak(field[4],6) + get_leak(field[6],0) + get_leak(field[7],7)
			4:
				return get_leak(field[0],3) + get_leak(field[1],4) + get_leak(field[2],5) + get_leak(field[3],2) \
						+ get_leak(field[5],6) + get_leak(field[6],1) + get_leak(field[7],0) + get_leak(field[8],7)
			5:
				return get_leak(field[1],3) + get_leak(field[2],4) + get_leak(field[4],2) + get_leak(field[7],1) + get_leak(field[8],0)
			6:
				return get_leak(field[3],4) + get_leak(field[4],5) + get_leak(field[7],6)
			7:
				return get_leak(field[3],3) + get_leak(field[4],4) + get_leak(field[5],5) + get_leak(field[6],2) + get_leak(field[8],6)
			8:
				return get_leak(field[4],3) + get_leak(field[5],4) + get_leak(field[7],2)

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
						player_total_power += player.deck[square.deck_index].power + get_total_leaks(p)
						explosion.positions.append(p)
						explosion.cards.append(player.deck[square.deck_index].id)
					elif square.owner == player.rival:
						rival_total_power += player.rival.deck[square.deck_index].power + get_total_leaks(p)
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
			var points : Dictionary = {}
			for pat in exp_pattern:
				for p in pat:
					points[p] = true
					field[p].opened = true
			
			var total_power := 0
			for p in points:
				var square := field[p]
				total_power += square.owner.deck[square.deck_index].power + get_total_leaks(p)
				explosion.positions.append(p)
				explosion.cards.append(square.owner.deck[square.deck_index].id)
			explosion.power = total_power
			player.rival.hp -= maxi(total_power,0)
			if player.rival.hp > 0:
				exturn_player = player.rival
			else:
				turn_player = null
			
			for p in points:
				var square := field[p]
				player.discard.append(square.deck_index)
				square.reset()
		
			return explosion
		
