extends Panel

signal back_button_pressed
signal server_list_changed

@onready var server_list : ItemList = %ServerList
@onready var additional_server : LineEdit = %AdditionalServer
@onready var sound_volume = %SoundVolume


# Called when the node enters the scene tree for the first time.
func _ready():
	%LineEditSaveDir.text =  OS.get_user_data_dir()

func initialize():
	server_list.clear()
	for s in Global.settings.server_list:
		server_list.add_item(s)
	sound_volume.initialize()


func _on_button_back_pressed():
	back_button_pressed.emit()

func _on_button_save_pressed():
	Global.settings.save()

func _on_add_button_pressed():
	server_list.add_item(additional_server.text)
	var list = Global.settings.server_list
	list.append(additional_server.text)
	Global.settings.server_list = list
	server_list_changed.emit()

func _on_delete_button_pressed():
	var select = server_list.get_selected_items()
	if not select.is_empty():
		server_list.remove_item(select[0])
		var list = Global.settings.server_list
		list.remove_at(select[0])
		Global.settings.server_list = list
		server_list_changed.emit()

