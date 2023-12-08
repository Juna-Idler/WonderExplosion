extends Node

@onready var canvas_layer = $CanvasLayer

@onready var match_scene = $Match


# Called when the node enters the scene tree for the first time.
func _ready():
	match_scene.set_process(false)
	pass # Replace with function body.


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
	pass



func _on_button_pressed():
	match_scene.set_process(true)
	match_scene.initialize()
	canvas_layer.hide()


func _on_match_requested_return():
	match_scene.set_process(false)
	canvas_layer.show()
