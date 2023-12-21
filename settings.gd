
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

var server_list : PackedStringArray :
	get:
		return config.get_value("Online","ServerList",["wss://wonder-explosion.onrender.com"])
	set(v):
		config.set_value("Online","ServerList",v)


func initialize_sound_config():
	var master_db : float = config.get_value("Sound","MasterDb",0.0)
	var bgm_db : float = config.get_value("Sound","BGMDb",0.0)
	var se_db : float = config.get_value("Sound","SEDb",0.0)
	var master_mute : bool = config.get_value("Sound","MasterMute",false)
	var bgm_mute : bool = config.get_value("Sound","BGMMute",false)
	var se_mute : bool = config.get_value("Sound","SEMute",false)
	
	var idx := AudioServer.get_bus_index("Master")
	AudioServer.set_bus_volume_db(idx,master_db)
	AudioServer.set_bus_mute(idx,master_mute)
	idx = AudioServer.get_bus_index("BGM")
	AudioServer.set_bus_volume_db(idx,bgm_db)
	AudioServer.set_bus_mute(idx,bgm_mute)
	idx = AudioServer.get_bus_index("SE")
	AudioServer.set_bus_volume_db(idx,se_db)
	AudioServer.set_bus_mute(idx,se_mute)

func store_sound_config():
	var idx := AudioServer.get_bus_index("Master")
	config.set_value("Sound","MasterDb",AudioServer.get_bus_volume_db(idx))
	config.set_value("Sound","MasterMute",AudioServer.is_bus_mute(idx))
	idx = AudioServer.get_bus_index("BGM")
	config.set_value("Sound","BGMDb",AudioServer.get_bus_volume_db(idx))
	config.set_value("Sound","BGMMute",AudioServer.is_bus_mute(idx))
	idx = AudioServer.get_bus_index("SE")
	config.set_value("Sound","SEDb",AudioServer.get_bus_volume_db(idx))
	config.set_value("Sound","SEMute",AudioServer.is_bus_mute(idx))


