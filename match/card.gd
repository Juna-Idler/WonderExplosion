extends Area3D

class_name Card

var data : Mechanics.CardData = null

var tween : Tween

var field_power_source : int = 0

func get_current_power() -> int:
	assert(data != null)
	return data.power + field_power_source

@onready var label_3d : Label3D = $Label3D

func _ready():
	tween = create_tween()
	tween.kill()

func initialize(color : Color,opponent : bool):
	var material := $BackSide.material_override as StandardMaterial3D
	material.albedo_color = color
	label_3d.hide()
	if opponent:
		label_3d.rotation.y = -PI

func set_open_data(card_data : Mechanics.CardData,texture : Texture2D):
	data = card_data
	var material := $FrontSide.material_override as StandardMaterial3D
	material.albedo_texture = texture

const DISABLE_CARD_OVERLAY_MATERIAL = preload("res://match/disable_card_overlay_material.tres")
func set_disable():
	$FrontSide.material_overlay = DISABLE_CARD_OVERLAY_MATERIAL

func set_enable():
	$FrontSide.material_overlay = null

func show_power(plus_power : int):
	field_power_source = plus_power
	var power := data.power + plus_power
	label_3d.text = str(power)
	label_3d.show()

func hide_power():
	label_3d.hide()
	label_3d.position = Vector3(0,0.1,0)
	field_power_source = 0

func separate_power():
	var tw := create_tween()
	tw.tween_property(label_3d,"position:x",-0.75,0.2)

