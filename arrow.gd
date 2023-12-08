@tool

extends Node3D

@onready var mesh_instance_3d := $MeshInstance3D




# Called when the node enters the scene tree for the first time.
func _ready():
	var material := mesh_instance_3d.get_active_material(0) as StandardMaterial3D
	material.albedo_texture = $SubViewport.get_texture()
	pass # Replace with function body.


func set_origin_and_target(origin : Vector3,target : Vector3):
	scale.z = (target - origin).length()
	position = (origin + target) / 2
	look_at(target)
	pass

