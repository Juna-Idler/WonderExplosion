extends Node

signal requested_return

const FIELD_SIZE := Vector2(3.3,3.3)


var game_server : IGameServer


var player_number := 0


var game_end := false

@onready var field : Field = $Board/Field

@onready var client_player : PlayablePlayer = $Board/Player
@onready var rival : NonPlayablePlayer = $Board/Rival

@onready var my_hp : Label = %MyHP
@onready var rival_hp : Label = %RivalHP

@onready var conflict_effect = $Board/ConflictEffect

@onready var camera_3d = $Board/Camera3D
@onready var explosion_power = %ExplosionPower
@onready var explosion_power_2 = %ExplosionPower2



func initialize(server : IGameServer):
	game_end = false
	%ResultMessage.hide()
	%ReturnButton.hide()
	
	game_server = server
	
	var first_data := await game_server._send_ready_async()
	
	var my_color := first_data.my_colors[0]
	var rival_color := first_data.rival_colors[0]
	
	client_player.initialize(first_data.my_name,first_data.my_deck,my_color,rival)
	rival.initialize_unknown(first_data.rival_name,rival_color,client_player,true)

	conflict_effect.set_color(my_color,rival_color)
	
	client_player.life_changed.connect(func(life):
		my_hp.text = "HP:" + str(life)
	)
	rival.life_changed.connect(func(life):
		rival_hp.text = "HP:" + str(life)
	)
	
	player_number = first_data.player_number
	field.initialize(client_player,player_number == 1)
	
	if player_number == 1:
		for i in first_data.my_hand:
			var _card := await client_player._draw_async(i)
		for i in first_data.rival_hand_count:
			var _card := await rival._draw_async()
		client_player.playable = true
	else:
		for i in first_data.rival_hand_count:
			var _card := await rival._draw_async()
		for i in first_data.my_hand:
			var _card := await client_player._draw_async(i)
		var result = await game_server._wait_async()
		await perform_result(result,rival)
		client_player.playable = true


func play(point_x : int,point_y : int):
	client_player.playable = false
	var index := client_player.get_play_card_index()
	var point := point_x + point_y * 3
	if player_number == 2:
		point = 8 - point
	var result := await game_server._play_async(index,point)
	if result == null:
		client_player.playable = true
		return
	await perform_result(result,client_player)
	if game_end:
		%ResultMessage.show()
		%ReturnButton.show()
	else:
		client_player.playable = true
	


func perform_result(result : IGameServer.Result, player : NonPlayablePlayer):
	var play_square := field.get_square(result.position)
	if result.battle:
		var card := await player._play_battle_async(play_square.global_position,result.play_card)
		card.show_power(0)
		var square_card := play_square.card
		play_square.secret = false
		await play_square.player._open_card_async(play_square.card,result.battle.card)
		square_card.show_power(0)
		await field.play_leak_effect_async(result.position)
		await play_square.player._counter_battle_async(square_card,result.battle.card)
		
		await perform_battle_effect(card,square_card,result.battle.result,result.player == player_number)
		
		card.hide_power()
		square_card.hide_power()
		if result.battle.result <= 0:
			if result.battle.result < 0:
				await player._discard_async(card)
			else:
				await player._bounce_async(card)
			var tween := create_tween().set_parallel()
			tween.tween_property(play_square.card,"global_position",play_square.global_position,0.5)
			tween.tween_property(play_square.card,"rotation:z",0.0,0.5)
			await tween.finished
		else:
			await play_square.player._discard_async(play_square.card)
			play_square.player = player
			play_square.card = card
			var tween := create_tween().set_parallel()
			tween.tween_property(card,"global_position",play_square.global_position,0.5)
			tween.tween_property(card,"rotation:z",0.0,0.5)
			await tween.finished
	else:
		var card := await player._play_set_async(play_square.global_position,result.play_card)
		play_square.player = player
		play_square.card = card
		play_square.secret = result.play_card == -1
	
	if result.explosion:
		var e := result.explosion
		var e_squares : Array[FieldSquare] = []
		
		for i in e.positions.size():
			var sq := field.get_square(e.positions[i])
			e_squares.append(sq)
			sq.secret = false
			await sq.player._open_card_async(sq.card,e.cards[i])
			sq.card.show_power(0)
		
		if e.other:
			var o_squares : Array[FieldSquare] = []
			for i in e.other.positions.size():
				var sq := field.get_square(e.other.positions[i])
				o_squares.append(sq)
				sq.secret = false
				await sq.player._open_card_async(sq.card,e.other.cards[i])
				sq.card.show_power(0)
			
			for i in e.positions.size():
				await field.play_leak_effect_async(e.positions[i])
			for i in e.other.positions.size():
				await field.play_leak_effect_async(e.other.positions[i])
				
			await perform_cross_explosion_effect(e.positions,e.other.positions,result.player == player_number)

			if e.power >= e.other.power:
				player.rival_player.life -= e.power
			if e.power <= e.other.power:
				player.life -= e.other.power

			if result.next_player == 0:
				game_end = true
				return
				
			if e.power >= e.other.power:
				for s in e_squares:
					s.card.hide_power()
					await s.player._discard_async(s.card)
					s.player = null
					s.card = null
			else:
				var tween := create_tween().set_parallel().set_ease(Tween.EASE_OUT)
				for s in e_squares:
					s.card.hide_power()
					tween.tween_property(s.card,"global_position",s.global_position,0.5)
				await tween.finished
			if e.power <= e.other.power:
				for s in o_squares:
					s.card.hide_power()
					await s.player._discard_async(s.card)
					s.player = null
					s.card = null
			else:
				var tween := create_tween().set_parallel().set_ease(Tween.EASE_OUT)
				for s in o_squares:
					s.card.hide_power()
					tween.tween_property(s.card,"global_position",s.global_position,0.5)
				await tween.finished
			
		else:
			for i in e.positions.size():
				await field.play_leak_effect_async(e.positions[i])
			await perform_explosion_effect(e.positions,result.player == player_number)
			player.rival_player.life -= e.power
			if result.next_player == 0:
				game_end = true
				return
			for s in e_squares:
				s.card.hide_power()
				await s.player._discard_async(s.card)
				s.player = null
				s.card = null
	
	if result.next_player == 0:
		game_end = true
		pass
	else:
		if result.next_player != player_number:
			for c in result.draw_cards:
				await rival._draw_async(c)
			var wait_result = await game_server._wait_async()
			await perform_result(wait_result,rival)
		else:
			if (result.battle and result.battle.result == 0) or\
					(result.explosion and not (result.explosion.other and result.explosion.power == result.explosion.other.power)):
				client_player.open_play = true
			else:
				client_player.open_play = false
			for c in result.draw_cards:
				await client_player._draw_async(c)


func perform_battle_effect(play_card : Card,square_card : Card,result : int,front_play : bool):
	var tween := create_tween().set_parallel()
	tween.tween_property(play_card,"position",Vector3(1.0,1.0,0),0.5)
	tween.tween_property(square_card,"position",Vector3(1.0,1.0,0),0.5)
	if result == 0:
		await conflict_effect.play_draw()
	else:
		if (result > 0) == front_play:
			await conflict_effect.play_win()
		else:
			await conflict_effect.play_lose()

const explosion_list : Array[Vector2] = [
	Vector2(-1,-0.5),Vector2(0,-0.5),Vector2(1,-0.5),
	Vector2(-1,0.5),Vector2(0,0.5),Vector2(1,0.5),
]

func perform_explosion_effect(positions : Array[int],front_play : bool):
	var power : int = 0
	if front_play:
		explosion_power.global_position = client_player.battle_point.global_position + Vector3(0,0,1)
	else:
		explosion_power.global_position = rival.battle_point.global_position + Vector3(0,0,1)
	explosion_power.text = "0"
	explosion_power.show()
	for i in positions.size():
		var sq := field.get_square(positions[i])
		var point := sq.player.battle_point.global_position
		point.x += explosion_list[i].x
		point.z += explosion_list[i].y 
		point.y = 0.5
		var tween := create_tween()
		tween.tween_property(sq.card,"global_position",point,0.5)
		await tween.finished
		power += sq.card.get_current_power()
		explosion_power.text = str(power)
	
	if front_play:
		await conflict_effect.play_win()
	else:
		await conflict_effect.play_lose()
	explosion_power.hide()

func perform_cross_explosion_effect(positions : Array[int],o_positions : Array[int],front_play : bool):
	if front_play:
		explosion_power.global_position = client_player.battle_point.global_position + Vector3(0,0,1)
		explosion_power_2.global_position = rival.battle_point.global_position + Vector3(0,0,1)
	else:
		explosion_power.global_position = rival.battle_point.global_position + Vector3(0,0,1)
		explosion_power_2.global_position = client_player.battle_point.global_position + Vector3(0,0,1)

	var power : int = 0
	explosion_power.text = "0"
	explosion_power.show()
	for i in positions.size():
		var sq := field.get_square(positions[i])
		var point := sq.player.battle_point.global_position
		point.x += explosion_list[i].x
		point.z += explosion_list[i].y 
		point.y = 0.5
		var tween := create_tween()
		tween.tween_property(sq.card,"global_position",point,0.5)
		await tween.finished
		power += sq.card.get_current_power()
		explosion_power.text = str(power)

	var power2 : int = 0
	explosion_power_2.text = "0"
	explosion_power_2.show()
	for i in o_positions.size():
		var sq := field.get_square(o_positions[i])
		var point := sq.player.battle_point.position
		point.x += explosion_list[i].x
		point.z += explosion_list[i].y 
		point.y = 0.5
		var tween := create_tween()
		tween.tween_property(sq.card,"position",point,0.5)
		await tween.finished
		power2 += sq.card.get_current_power()
		explosion_power_2.text = str(power2)
	if power == power2:
		await conflict_effect.play_draw()
	else:
		if front_play == (power > power2):
			await conflict_effect.play_win()
		else:
			await conflict_effect.play_lose()
	explosion_power.hide()
	explosion_power_2.hide()

func _on_player_selecting(hit_position):
	if (-FIELD_SIZE.x / 2 < hit_position.x and hit_position.x < FIELD_SIZE.x / 2 and
			-FIELD_SIZE.y / 2 < hit_position.z and hit_position.z < FIELD_SIZE.y / 2):
		var point_x : int = int((hit_position.x + FIELD_SIZE.x / 2) / (FIELD_SIZE.x / 3))
		var point_y : int = int((hit_position.z + FIELD_SIZE.y / 2) / (FIELD_SIZE.y / 3))
		for i in 9:
			if i == point_x + point_y * 3:
				var sq := field.get_client_square(point_x + point_y * 3)
				if sq.card == null:
					sq.set_color(Color(0.0,0.0,1.0,0.5))
				elif client_player.open_play:
					sq.set_color(Color(0.0,0.0,0.0,0.8))
				elif sq.player == client_player or not sq.secret:
					sq.set_color(Color(0.0,0.0,0.0,0.8))
				else:
					sq.set_color(Color(0.0,0.0,1.0,0.5))
			else:
				field.get_client_square(i).set_color(Color.TRANSPARENT)
	else:
		for i in 9:
			field.get_client_square(i).set_color(Color.TRANSPARENT)
	

func _on_player_decided(hit_position):
	if (-FIELD_SIZE.x / 2 < hit_position.x and hit_position.x < FIELD_SIZE.x / 2 and
			-FIELD_SIZE.y / 2 < hit_position.z and hit_position.z < FIELD_SIZE.y / 2):
		var point_x : int = int((hit_position.x + FIELD_SIZE.x / 2) / (FIELD_SIZE.x / 3))
		var point_y : int = int((hit_position.z + FIELD_SIZE.y / 2) / (FIELD_SIZE.y / 3))
		field.get_client_square(point_x + point_y * 3).set_color(Color.TRANSPARENT)
		play(point_x,point_y)



func _on_return_button_pressed():
	requested_return.emit()
