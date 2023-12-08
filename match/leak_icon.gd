extends MeshInstance3D

@onready var leak = $SubViewport/Leak
@onready var sub_viewport = $SubViewport

func initialize(power : int, direction : int):
	if power != 0:
		show()
		leak.initialize(power,direction)
		sub_viewport.render_target_update_mode = SubViewport.UPDATE_ONCE
	else:
		hide()

func _ready():
	(material_override as StandardMaterial3D).albedo_texture = sub_viewport.get_texture()
	pass
