extends SubViewport

@onready var frame_color = $FrameColor
@onready var texture_rect = $TextureRect
@onready var cover_color = $TextureRect/CoverColor

func initialize(color : Color,image : Texture2D,frame_width : float):
	frame_color.color = color
	cover_color.color = Color(color,0.5)
	texture_rect.texture = image
	var ratio := 1.0 - frame_width / 256.0
	texture_rect.scale = Vector2.ONE * ratio
	render_target_update_mode = SubViewport.UPDATE_ONCE
