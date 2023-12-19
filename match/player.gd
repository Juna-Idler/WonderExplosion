extends Node3D

class_name NonPlayablePlayer

signal life_changed(life : int)

const CardTextureScene = preload("res://card/card_texture.tscn")

const HANDAREA_SIZE := Vector2(4.0,1.1)
const CARD_WIDTH := 1.0

@onready var hand_area : Node3D = $HandArea
@onready var stock_area : Node3D = $StockArea
@onready var discard_area : Node3D = $DiscardArea
@onready var cards : Array[Card] = [$Card1,$Card2,$Card3,$Card4,$Card5,$Card6]
@onready var battle_point : Node3D = $BattlePoint
@onready var raised_point : Node3D = $RaisedPoint

@export var audio_stream_player : AudioStreamPlayer

var card_textures : Dictionary = {}


var stock : Array[Card]
var hand : Array[Card]
var discard : Array[Card]

var player_color : Color
var player_name : String
var life : int :
	set(v) :
		life = v
		life_changed.emit(life)

var rival_player : NonPlayablePlayer

var opponent_layout : bool

func initialize_unknown(p_name : String,color : Color,rival : NonPlayablePlayer,opponent : bool):
	for v in card_textures.values():
		remove_child(v)
		v.queue_free()
	card_textures.clear()
	player_name = p_name
	player_color = color
	life = 20
	stock = cards.duplicate()
	hand = []
	discard = []
	rival_player = rival
	opponent_layout = opponent
	for i in cards.size():
		var card := cards[i]
		card.initialize(color,opponent)
		card.position = stock_area.position
		card.position.y = 0.01 * (i + 1)
		card.rotation = Vector3(0,0,-PI)


func _draw_async(deck_index : int = -1) -> Card:
	var tween : Tween
	if stock.is_empty():
		stock = discard
		discard = []

		tween = create_tween()
		for i in stock.size():
			var c := stock[i]
			var pos := (stock_area.position + discard_area.position) / 2
			pos.y += 1.0
			tween.parallel().tween_property(c,"position",pos,0.5)
			tween.parallel().tween_property(c,"rotation:z",-PI,0.5)
			pos = Vector3(stock_area.position.x,stock_area.position.y + 0.01 * (i + 1),stock_area.position.z)
			tween.parallel().tween_property(c,"position",pos,0.5)
			tween.parallel().tween_property(c,"rotation:z",-PI,0.5)
		await tween.finished
		if deck_index == -1:
			for c in stock:
				c.set_open_data(null,null)
			
	var card : Card
	if deck_index == -1:
		card = stock.pop_back()
	else:
		card = cards[deck_index]
		var swap := card.position
		card.position = stock[-1].position
		stock[-1].position = swap
		stock.erase(card)
	hand.push_back(card)

	var step := HANDAREA_SIZE.x / (hand.size() + 1)
	var start := step - HANDAREA_SIZE.x/2
	if step < 1 + 0.1:
		start = step / 10
		step = (HANDAREA_SIZE.x - 1 - start*2) / (hand.size() - 1);
		start -= (HANDAREA_SIZE.x - CARD_WIDTH)/2
	tween = create_tween().set_parallel().set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_LINEAR)
	for i in hand.size() - 1:
		var c := hand[i]
		var target := Vector3(start + i * step,0.01,hand_area.position.z)
		tween.tween_property(c,"position",target,0.5)
		
	tween.set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)
	if deck_index != -1:
		tween.tween_property(card,"rotation:z",0,0.25)
		tween.tween_property(card,"position",Vector3(stock_area.position.x /2,1.0,stock_area.position.z /2),0.25)
		tween.set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN)
		tween.set_parallel(false)
		tween.tween_property(card,"position",Vector3(start + (hand.size()-1) * step,0.01,hand_area.position.z),0.25)
	else:
		tween.tween_property(card,"position",Vector3(start + (hand.size()-1) * step,0.01,hand_area.position.z),0.5)
	await tween.finished
	return card

func _play_card() -> Card:
	return hand.pop_at(0)


func _play_set_async(point : Vector3,card_id : int = -1) -> Card:
	var card := _play_card()
	var flip := -PI 
	if card_id != -1:
		if card.data == null:
			_set_card_texture(card,card_id)
		flip = 0.0

	audio_stream_player.stream = preload("res://sounds/決定ボタンを押す13.mp3")
	var tween := create_tween().set_ease(Tween.EASE_OUT)
	tween.tween_property(card,"position",raised_point.position,0.5).set_trans(Tween.TRANS_QUAD)
	tween.parallel().tween_property(card,"rotation:z",flip,0.5)
	tween.tween_callback(audio_stream_player.play)
	tween.tween_property(card,"global_position",point,0.5).set_trans(Tween.TRANS_QUAD)
	await tween.finished
	return card

func _play_battle_async(point : Vector3,card_id : int) -> Card:
	var card := _play_card()
	if card.data == null:
		_set_card_texture(card,card_id)

	audio_stream_player.stream = preload("res://sounds/決定ボタンを押す1.mp3")
	var tween := create_tween().set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_QUAD)
	tween.tween_property(card,"position",raised_point.position,0.5)
	tween.parallel().tween_property(card,"rotation:z",0,0.5)
	point.y += 0.1
	tween.tween_property(card,"global_position",point,0.5)
	tween.tween_callback(card.separate_power)
	tween.tween_callback(audio_stream_player.play)
	tween.tween_property(card,"position",battle_point.position,0.5)
	await tween.finished
	return card

func _counter_battle_async(card : Card,card_id : int):
	_set_card_texture(card,card_id)
	var tween := create_tween().set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_QUAD)
	tween.tween_callback(card.separate_power)
	tween.tween_property(card,"position",battle_point.position,0.5)
	tween.parallel().tween_property(card,"rotation:z",0,0.5)
	await tween.finished


func _discard_async(card : Card):
	discard.append(card)
	audio_stream_player.stream = preload("res://sounds/パフ.mp3")
	var tween := create_tween().set_parallel()
	var pos := Vector3(discard_area.position.x,discard_area.position.y + discard.size() * 0.01,discard_area.position.z)
	tween.tween_property(card,"position",pos,0.5)
	tween.tween_property(card,"rotation:z",0,0.5)
	tween.tween_callback(audio_stream_player.play)
	await tween.finished

func _bounce_async(card : Card):
	hand.push_front(card)

	var step := HANDAREA_SIZE.x / (hand.size() + 1)
	var start := step - HANDAREA_SIZE.x/2
	if step < 1 + 0.1:
		start = step / 10
		step = (HANDAREA_SIZE.x - 1 - start*2) / (hand.size() - 1);
		start -= (HANDAREA_SIZE.x - CARD_WIDTH)/2
	var tween := create_tween().set_parallel().set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_CUBIC)
	for i in hand.size():
		var c := hand[i]
		var target := Vector3(start + i * step,0.01,hand_area.position.z)
		tween.tween_property(c,"position",target,0.5)
	await tween.finished



func _open_card_async(card : Card,card_id : int):
	if card.data == null:
		_set_card_texture(card,card_id)
	var original_pos := card.position
	var tween := create_tween()
	var pos := original_pos + Vector3(0,0.25,0)
	tween.tween_property(card,"position",pos,0.2)
	tween.parallel().tween_property(card,"rotation:z",0,0.4)
	tween.tween_property(card,"position",original_pos,0.2)
	
	audio_stream_player.stream = preload("res://sounds/刀の素振り1.mp3")
	audio_stream_player.play()
	await tween.finished


func _set_card_texture(card : Card,card_id : int):
	var data := Global.card_list.get_card_data(card_id)
	if not card_textures.has(card_id):
		var ct := CardTextureScene.instantiate()
		add_child(ct)
		ct.initialize(data,player_color,null,opponent_layout)
		card_textures[card_id] = ct
	card.set_open_data(data,card_textures.get(card_id).get_texture())


