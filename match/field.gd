extends Node3D

class_name Field

@export var audio_stream_player : AudioStreamPlayer

@onready var leak_effect = $LeakEffect

@onready var squares : Array[FieldSquare] = [
	$Square1,
	$Square2,
	$Square3,
	$Square4,
	$Square5,
	$Square6,
	$Square7,
	$Square8,
	$Square9,
]
@onready var client_squares : Array[FieldSquare] = squares.duplicate()

var reverse : bool = false

var front_side_player : NonPlayablePlayer

func initialize(player : NonPlayablePlayer,first : bool):
	front_side_player = player
	if reverse != not first:
		reverse = not first
		squares.reverse()
	for s in squares:
		s.initialize()

func get_square(index : int) -> FieldSquare:
	return squares[index]

func get_client_square(index : int) -> FieldSquare:
	return client_squares[index]


# Called when the node enters the scene tree for the first time.
func _ready():
	pass # Replace with function body.


func get_leak(x : int,y : int, direction : int) -> int:
	if x < 0 or x >= 3 or y < 0 or y >= 3:
		return 0
	return squares[x + y * 3].get_leak(direction,front_side_player)

func get_square_leaks(index : int) -> PackedInt32Array:
	var x := index % 3
	@warning_ignore("integer_division")
	var y := index / 3
	if reverse:
		return PackedInt32Array([
			get_leak(x,y + 1,4),
			get_leak(x - 1,y + 1,5),
			get_leak(x - 1,y,6),
			get_leak(x - 1,y - 1,7),
			get_leak(x,y-1,0),
			get_leak(x + 1,y - 1,1),
			get_leak(x + 1,y,2),
			get_leak(x + 1,y + 1,3),

		])
	else:
		return PackedInt32Array([
			get_leak(x,y-1,4),get_leak(x + 1,y - 1,5),
			get_leak(x + 1,y,6),get_leak(x + 1,y + 1,7),
			get_leak(x,y + 1,0),get_leak(x - 1,y + 1,1),
			get_leak(x - 1,y,2),get_leak(x - 1,y - 1,3)
		])

func play_leak_effect_async(index : int):
	var card := get_square(index).card
	var leaks := get_square_leaks(index)
	if leak_effect.set_leaks(leaks):
		audio_stream_player.stream = preload("res://sounds/ステータス上昇魔法2.mp3")
		audio_stream_player.play()
		await leak_effect.play(card.global_position,0.65)
		var total : int = 0
		for i in leaks:
			total += i
		card.show_power(total)
		await get_tree().create_timer(0.1).timeout

