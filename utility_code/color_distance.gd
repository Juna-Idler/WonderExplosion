
class_name ColorDistance

const NEAR_COLOR_DISTANCE := 1.0

static func near_color(c1 : Color,c2 : Color) -> bool:
	return get_distance2(c1,c2) < NEAR_COLOR_DISTANCE ** 2

static func get_distance2(c1 : Color,c2 : Color) -> float:
	return pow(c1.r - c2.r,2) + pow(c1.g - c2.g,2) + pow(c1.b - c2.b,2)


static func get_accepted_color(c : Color,target : Color, distance : float) -> Color:
	if c == target:
		return Color.TRANSPARENT
	var d := get_distance2(c,target)
	if d >= distance ** 2:
		return c
	var v := Vector3(c.r - target.r,c.g - target.g,c.b - target.b).normalized()
	v = Vector3(target.r,target.g,target.b) + v * distance
	v = clamp(v,Vector3.ZERO,Vector3.ONE)
	return Color(v.x,v.y,v.z)

