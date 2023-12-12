extends Node3D

class_name FieldSquare

var card : Card = null
var player : NonPlayablePlayer = null
var secret : bool = true

# Called when the node enters the scene tree for the first time.
func _ready():
	pass # Replace with function body.

func initialize():
	card = null
	player = null
	secret = true

func set_color(color : Color):
	var materila := $MeshInstance3D.material_override as StandardMaterial3D
	materila.albedo_color = color

func get_leak(direction : int,player_side : NonPlayablePlayer) -> int:
	if player == null or card == null or secret:
		return 0
	
	if player == player_side:
		return card.data.arrows[direction]
	else:
		return card.data.arrows[(direction + 4) % 8]
	

