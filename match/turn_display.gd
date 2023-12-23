extends Path3D

@onready var path_follow_3d = $PathFollow3D
@onready var label_3d = $PathFollow3D/Label3D

var tween : Tween

func wait_finished():
	if tween.is_running():
		await tween.finished

# Called when the node enters the scene tree for the first time.
func _ready():
	tween = create_tween()
	tween.kill()


func initialize():
	path_follow_3d.progress_ratio = 0.5
	label_3d.text = "Game Start"


func move_to_client(turn : int, ex : bool):
	tween.kill()
	tween = create_tween()
	tween.tween_property(path_follow_3d,"progress_ratio",0.5,0.3)
	tween.tween_callback(func():label_3d.text = "Turn %d" % turn + (" Ex" if ex else ""))
	tween.tween_interval(0.4)
	tween.tween_property(path_follow_3d,"progress_ratio",1.0,0.3)

func move_to_rival(turn : int, ex : bool):
	tween.kill()
	tween = create_tween()
	tween.tween_property(path_follow_3d,"progress_ratio",0.5,0.3)
	tween.tween_callback(func():label_3d.text = "Turn %d" % turn + (" Ex" if ex else ""))
	tween.tween_interval(0.4)
	tween.tween_property(path_follow_3d,"progress_ratio",0.0,0.3)

