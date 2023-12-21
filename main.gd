extends Node

@onready var title_layer = $TitleLayer
@onready var build_layer = $BuildLayer
@onready var match_ui_layer = $MatchUILayer

@onready var title_settings = $TitleLayer/TitleSettings

@onready var result_display = %ResultDisplay
@onready var settings = %Settings


@onready var result_message = %ResultMessage

@onready var match_scene = $Match
@onready var build = %Build
@onready var deck_set_label = %DeckSetLabel

@onready var player_name_edit = %PlayerName

@onready var server_option_button : OptionButton = %ServerOptionButton


var player_name : String = "no name"
var player_deck : Deck

var offline_server := OfflineServer.new()

# Called when the node enters the scene tree for the first time.
func _ready():
	match_ui_layer.hide()
	result_display.hide()
	build_layer.hide()
	title_layer.show()
	
	
	Global.settings.load()

	for s in Global.settings.server_list:
		server_option_button.add_item(s)
	server_option_button.select(0)
	
	player_deck = Global.settings.deck
	player_name = Global.settings.player_name
	player_name_edit.text = player_name

	deck_set_label.initialize(player_deck)
	match_scene.set_process(false)
	build.set_process(false)
	
	Global.settings.initialize_sound_config()



# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(_delta):
	pass



func _on_button_pressed():
	offline_server.initialize(player_name,player_deck.cards,player_deck.cards,
			[player_deck.primary_color,player_deck.secondary_color],
			[player_deck.secondary_color,player_deck.primary_color])
	match_scene.set_process(true)
	match_scene.initialize(offline_server)
	match_ui_layer.show()
	settings.hide()
	result_display.hide()
	title_layer.hide()



func _on_build_button_pressed():
	build.set_process(true)
	build.initialize(player_deck)
	build_layer.show()
	title_layer.hide()



func _on_build_back_button_pressed():
	build.set_process(false)
	build_layer.hide()
	title_layer.show()


func _on_build_request_save(deck):
	player_deck = deck
	Global.settings.deck = deck
	Global.settings.save()
	deck_set_label.initialize(deck)



func _on_online_button_pressed():
	var selected = server_option_button.selected
	if selected < 0:
		return
	server_option_button.get_item_text(selected)
	Global.settings.online_url = server_option_button.get_item_text(selected)
	Global.settings.save()
	get_tree().change_scene_to_file("res://online/main.tscn")


func _on_player_name_text_changed(new_text):
	player_name = new_text
	Global.settings.player_name = player_name

func _on_player_name_text_submitted(_new_text):
	Global.settings.save()



func _on_match_finished(player_life, rival_life):
	var result := int(rival_life <= 0) - int(player_life <= 0)
	if result > 0:
		result_message.text = "YOU WIN"
		match_scene.audio_stream_player.stream = preload("res://sounds/レベルアップ.mp3")
		match_scene.audio_stream_player.play()
	elif result < 0:
		match_scene.audio_stream_player.stream = preload("res://sounds/呪いの旋律.mp3")
		match_scene.audio_stream_player.play()
		result_message.text = "YOU LOSE"
	else:
		result_message.text = "DRAW"
	settings.hide()
	result_display.show()

func _on_return_button_pressed():
	match_ui_layer.hide()
	match_scene.set_process(false)
	title_layer.show()
	


func _on_settings_button_pressed():
	settings.show()


func _on_back_button_pressed():
	settings.hide()



func _on_title_settings_button_pressed():
	title_settings.initialize()
	title_settings.show()

func _on_title_settings_back_button_pressed():
	title_settings.hide()

func _on_title_settings_server_list_changed():
	server_option_button.clear()
	for s in Global.settings.server_list:
		server_option_button.add_item(s)
	server_option_button.select(0)
	

