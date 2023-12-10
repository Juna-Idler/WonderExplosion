extends Node3D


const ENTRY_TIME := 0.5
const RESULT_TIME := 1.0

@onready var my_force = $MyForce
@onready var rival_force = $RivalForce
@onready var draw = $Draw

func set_color(my_color : Color,rival_color : Color):
	my_force.mesh.material.albedo_color = my_color
	rival_force.mesh.material.albedo_color = rival_color


func play_win():
	my_force.mesh.center_offset.z = 10.0
	rival_force.mesh.center_offset.z = -10.0
	show()
	var tween := create_tween()
	tween.set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_LINEAR)
	tween.tween_property(my_force.mesh,"center_offset:z",5,ENTRY_TIME)
	tween.parallel().tween_property(rival_force.mesh,"center_offset:z",-5,ENTRY_TIME)
	tween.set_trans(Tween.TRANS_QUAD)
	tween.tween_property(my_force.mesh,"center_offset:z",0.0,RESULT_TIME)
	tween.parallel().tween_property(rival_force.mesh,"center_offset:z",-10,RESULT_TIME)
	await tween.finished
	hide()

func play_lose():
	my_force.mesh.center_offset.z = 10.0
	rival_force.mesh.center_offset.z = -10.0
	show()
	var tween := create_tween()
	tween.set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_LINEAR)
	tween.tween_property(my_force.mesh,"center_offset:z",5,ENTRY_TIME)
	tween.parallel().tween_property(rival_force.mesh,"center_offset:z",-5,ENTRY_TIME)
	tween.set_trans(Tween.TRANS_QUAD)
	tween.tween_property(my_force.mesh,"center_offset:z",10.0,RESULT_TIME)
	tween.parallel().tween_property(rival_force.mesh,"center_offset:z",0,RESULT_TIME)
	await tween.finished
	hide()

func play_draw():
	my_force.mesh.center_offset.z = 10.0
	rival_force.mesh.center_offset.z = -10.0
	draw.mesh.size.y = 0
	show()
	var tween := create_tween()
	tween.set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_LINEAR)
	tween.tween_property(my_force.mesh,"center_offset:z",5,ENTRY_TIME)
	tween.parallel().tween_property(rival_force.mesh,"center_offset:z",-5,ENTRY_TIME)
	tween.set_trans(Tween.TRANS_QUAD)
	tween.tween_property(draw.mesh,"size:y",10.0,RESULT_TIME)
	await tween.finished
	hide()
	$Draw.mesh.size.y = 0


