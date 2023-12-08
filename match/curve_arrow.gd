extends Node3D

@onready var path_follow_3d = $Path3D/PathFollow3D

@onready var sprite_3d_edge = $Sprite3D9

@onready var sub_viewport = $SubViewport
@onready var sub_viewport_2 = $SubViewport2


var sprites : Array
var ratio : float = 0.0

# Called when the node enters the scene tree for the first time.
func _ready():
	for i in 8:
		var sprite := get_node("Sprite3D" + str(i + 1)) as Sprite3D
		sprite.texture = sub_viewport.get_texture()
		sprites.append(sprite)
	$Sprite3D9.texture = sub_viewport_2.get_texture()
	$Path3D/PathFollow3D.use_model_front = true
	pass # Replace with function body.


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
	ratio += delta/2
	if ratio > 1.0:
		ratio -= 1.0
	for i in 8:
		path_follow_3d.progress_ratio = ratio + (i + 1) * (1.0 / 8)
		sprites[i].global_position = path_follow_3d.global_position
		sprites[i].global_rotation.y = path_follow_3d.global_rotation.y
	pass


func set_origin_and_target(origin : Vector3,target : Vector3,tilt : float = 0.0):
	position = origin
	var vector := target - origin
	$Path3D.scale.z = vector.length()
	$Path3D.look_at(target)
	$Path3D.rotate(vector.normalized(),tilt)
	sprite_3d_edge.position = vector
	alignment()

func alignment():
	for i in 8:
		path_follow_3d.progress_ratio = (i + 1) * (1.0 / 8)
		sprites[i].global_position = path_follow_3d.global_position
		sprites[i].rotation.y = path_follow_3d.rotation.y



