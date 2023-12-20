
class_name Settings

const FILE_PATH := "user://config.cfg"

var config := ConfigFile.new()



func save():
	config.save(FILE_PATH)

func load():
	if config.load(FILE_PATH) != OK:
		pass

var player_name : String :
	get:
		return config.get_value("Player","Name","no name")
	set(name):
		config.set_value("Player","Name",name)

var deck : Deck :
	get:
		var name : String = config.get_value("Deck","Name","no name")
		var cards : PackedInt32Array = config.get_value("Deck","Cards",[1,2,3,4,5,6])
		var colors : PackedColorArray = config.get_value("Deck","Colors",[Color.BLUE,Color.RED])
		return Deck.new(name,cards,colors[0],colors[1])
	set(d):
		config.set_value("Deck","Name",d.name)
		config.set_value("Deck","Cards",PackedInt32Array(d.cards))
		config.set_value("Deck","Colors",[d.primary_color,d.secondary_color])

var online_url : String :
	get:
		return config.get_value("Online","Server URL","wss://wonder-explosion.onrender.com")
	set(v):
		config.set_value("Online","Server URL",v)
