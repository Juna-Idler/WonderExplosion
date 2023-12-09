
class_name Deck

var name : String
var cards : Array[int]
var primary_color : Color
var secondary_color : Color
var index : int


func _init(n : String,c : Array[int],p_color : Color,s_color : Color, i : int = 0):
	assert(c.size() == 6)
	assert(i >= 0 and i < 6)
	name = n
	cards = c
	primary_color = p_color
	secondary_color = s_color
	index = i

