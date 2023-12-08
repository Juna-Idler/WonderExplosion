extends SubViewport

var data : Mechanics.CardData

@onready var card_face = $CardFace


func initialize(card_data : Mechanics.CardData,color : Color,texture : Texture2D,opponent : bool):
	assert(card_data != null)
	data = card_data
	card_face.initialize(card_data,color,texture,opponent)
	render_target_update_mode = SubViewport.UPDATE_ONCE
