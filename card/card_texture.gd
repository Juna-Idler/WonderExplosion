extends SubViewport

class_name CardTexture

var data : CardList.CardData

@onready var card_face : Control = $CardFace
@onready var color_rect = $ColorRect


func initialize(card_data : CardList.CardData,color : Color,frame_width : float):
	assert(card_data != null)
	data = card_data
	color_rect.color = color
	card_face.initialize(card_data)
	var ratio := 1.0 - frame_width / 256.0
	card_face.scale = Vector2.ONE * ratio
	render_target_update_mode = SubViewport.UPDATE_ONCE
