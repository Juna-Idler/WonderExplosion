extends Control


# Called when the node enters the scene tree for the first time.
func _ready():
	pass

func initialize():
	set_sound("Master")
	set_sound("BGM")
	set_sound("SE")

func set_sound(bus_name:String):
	var idx := AudioServer.get_bus_index(bus_name)
	var volume := db_to_linear(AudioServer.get_bus_volume_db(idx))
	var mute := AudioServer.is_bus_mute(idx)
	var slider := get_node("HSlider" + bus_name) as HSlider
	slider.value = volume
	var cb := slider.get_node("CheckButton" + bus_name) as CheckButton
	cb.button_pressed = not mute
	slider.self_modulate.a = 1.0 if cb.button_pressed else 0.5


func _on_h_slider_master_value_changed(value):
	var idx := AudioServer.get_bus_index("Master")
	AudioServer.set_bus_volume_db(idx,linear_to_db(value))
	Global.settings.store_sound_config()

func _on_h_slider_bgm_value_changed(value):
	var idx := AudioServer.get_bus_index("BGM")
	AudioServer.set_bus_volume_db(idx,linear_to_db(value))
	Global.settings.store_sound_config()

func _on_h_slider_se_value_changed(value):
	var idx := AudioServer.get_bus_index("SE")
	AudioServer.set_bus_volume_db(idx,linear_to_db(value))
	Global.settings.store_sound_config()


func _on_check_button_master_toggled(button_pressed):
	var idx := AudioServer.get_bus_index("Master")
	AudioServer.set_bus_mute(idx,not button_pressed)
	%HSliderMaster.self_modulate.a = 1.0 if button_pressed else 0.5
	Global.settings.store_sound_config()

func _on_check_button_bgm_toggled(button_pressed):
	var idx := AudioServer.get_bus_index("BGM")
	AudioServer.set_bus_mute(idx,not button_pressed)
	%HSliderBGM.self_modulate.a = 1.0 if button_pressed else 0.5
	Global.settings.store_sound_config()

func _on_check_button_se_toggled(button_pressed):
	var idx := AudioServer.get_bus_index("SE")
	AudioServer.set_bus_mute(idx,not button_pressed)
	%HSliderSE.self_modulate.a = 1.0 if button_pressed else 0.5
	Global.settings.store_sound_config()

