extends NonPlayablePlayer

class_name PlayablePlayer

signal selecting(position : Vector3)
signal decided(position : Vector3)


var playable : bool = false
var open_play : bool = false


const FIELD_SIZE := Vector2(3.3,3.3)


@onready var drag_plane = %DragPlane
@onready var curve_arrow = $CurveArrow


var _click : bool = false
var _drag_card : Card = null

var _decide_card : Card = null

var _bounce_card : Card = null


func initialize(p_name : String,deck : Array[int],color : Color,rival : NonPlayablePlayer):
	playable = false
	super.initialize_unknown(p_name,color,rival,false)
	for i in deck.size():
		super._set_card_texture(cards[i],deck[i])


func _ready():
	for c in cards:
		c.input_event.connect(_on_card_input_event.bind(c))
	pass # Replace with function body.

func _play_card() -> Card:
	var card : Card = _bounce_card if _bounce_card else _decide_card
	var index := hand.find(card)
	if _bounce_card:
		for c in hand:
			c.set_enable()
		_bounce_card = null
	_decide_card = null
	return hand.pop_at(index)

func get_play_card_index() -> int:
	var card : Card = _bounce_card if _bounce_card else _decide_card
	return cards.find(card)
	
func _bounce_async(card : Card):
	super(card)
	_bounce_card = card
	for c in hand:
		if c != card:
			c.set_disable()

func _on_card_input_event(_camera, event,hit_position, _normal, _shape_idx,card):
	if _click:
		if event is InputEventMouseMotion:
			if playable and hand.has(card):
				if _bounce_card and card != _bounce_card:
					return
				_decide_card = null
				_drag_card = card
				card.set_ray_pickable(false)
				drag_plane.input_ray_pickable = true

				curve_arrow.set_origin_and_target(_drag_card.position,hit_position)
				curve_arrow.show()
			_click = false
		else:
			if (event is InputEventMouseButton
					and event.button_index == MOUSE_BUTTON_LEFT
					and not event.pressed):
				_click = false
	else:
		if (event is InputEventMouseButton
				and event.button_index == MOUSE_BUTTON_LEFT
				and event.pressed):
			_click = true


func _on_drag_plane_input_event(_camera, event, hit_position, _normal, _shape_idx):
	if _drag_card:
		var tilt : float = 0
		if _drag_card.position.x < -0.5:
			tilt = -PI / 2
		elif _drag_card.position.x > 0.5:
			tilt = PI / 2
		else:
			if hit_position.x < _drag_card.position.x - 0.5:
				tilt = -PI / 2
			elif hit_position.x > _drag_card.position.x + 0.5:
				tilt = PI / 2
			else:
				tilt = PI * (hit_position.x - _drag_card.position.x)
		curve_arrow.set_origin_and_target(_drag_card.position,hit_position,tilt)
		selecting.emit(hit_position)
		
	if event is InputEventMouse:
		if (event is InputEventMouseButton
				and event.button_index == MOUSE_BUTTON_LEFT
				and not event.pressed):
			drag_plane.input_ray_pickable = false
			_drag_card.set_ray_pickable(true)
			curve_arrow.hide()
			_decide_card = _drag_card
			decided.emit(hit_position)
			_drag_card = null
			return
		if event is InputEventMouseMotion:
			pass


func _on_drag_plane_mouse_exited():
	if _drag_card:
		drag_plane.input_ray_pickable = false
		_drag_card.set_ray_pickable(true)
		_drag_card = null
		curve_arrow.hide()

