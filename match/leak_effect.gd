extends Node3D

@onready var leak_icons = [
	$LeakIcon0,
	$LeakIcon1,
	$LeakIcon2,
	$LeakIcon3,
	$LeakIcon4,
	$LeakIcon5,
	$LeakIcon6,
	$LeakIcon7,
]


@onready var animation_player = $AnimationPlayer


func set_leaks(leaks : PackedInt32Array) -> bool:
	var result := false
	for i in 8:
		leak_icons[i].initialize(leaks[i],(i + 4) % 8)
		if leaks[i] != 0:
			result = true
	return result

func play(play_global_position : Vector3,duration : float = 0.5):
	global_position = play_global_position
	animation_player.stop()
	show()
	animation_player.speed_scale = 0.5 / duration
	animation_player.play("gather")
	await animation_player.animation_finished
	hide()


