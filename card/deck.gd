
class_name Deck

var name : String
var cards : PackedInt32Array
var colors : PackedColorArray
var primary_color : Color
var secondary_color : Color


func _init(n : String,c : PackedInt32Array,p_color : Color,s_color : Color):
	assert(c.size() == 6)
	name = n
	cards = c
	primary_color = p_color
	secondary_color = s_color

