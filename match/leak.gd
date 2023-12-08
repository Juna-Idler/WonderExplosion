extends Control

@onready var polygon_2d : Polygon2D = $Polygon2D
@onready var line_2d = $Polygon2D/Line2D
@onready var label : Label = $Label


func initialize(power : int, direction : int):
	var color : Color
	if power == 0:
		label.text = ""
		color = Color.GRAY
	else:
		color = Color.RED if power > 0 else Color.BLUE
		label.text = "%+d" % power
	polygon_2d.rotation = -PI/2 + direction * PI/4
	polygon_2d.color = color
	line_2d.default_color = color.darkened(0.30)
	label.label_settings.outline_color = line_2d.default_color

