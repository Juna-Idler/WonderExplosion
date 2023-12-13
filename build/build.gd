extends Panel

signal back_button_pressed
signal request_save(deck : Deck)

const DRAGGABLE_ITEM = preload("res://build/draggable_item.tscn")
const CARD_TEXTURE = preload("res://card/card_texture.tscn")

@onready var item_list : ItemList = %ItemList

var card_textures : Dictionary = {}

var pack_select_list : Dictionary = {}

@onready var pack_list = %PackList
@onready var deck_list : GridContainer = %DeckList

@onready var mover : TextureRect = %Mover
@onready var deck_name = %DeckName

@onready var primary_color_button = %PrimaryColor
@onready var secondary_color_button = %SecondaryColor

var primary_color : Color
var secondary_color : Color

@onready var deck_power = %DeckPower
const DECK_POWER_TEXT := "DECK (%d)"
var deck_power_point : int = 0

@onready var save_button = %SaveButton


# Called when the node enters the scene tree for the first time.
func _ready():
	var d := Deck.new("",[1,2,3,4,5,6],Color.BLUE,Color.RED)
	initialize(d)
	pass # Replace with function body.


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(_delta):
	pass

func initialize(deck : Deck):
	var card_list := Global.card_list.card_list.duplicate()
	card_list.pop_front()
	item_list.clear()
	var index := item_list.add_item("ALL")
	pack_select_list[index] = PackedInt32Array(card_list.map(func(v:CardList.CardData):return v.id))
	for p in Global.card_list.pack_list:
		var i := item_list.add_item(p.name)
		pack_select_list[i] = p.include_ids
	item_list.select(1)
	initialize_pack_card_list(1)

	for c in deck_list.get_children():
		deck_list.remove_child(c)
		c.queue_free()
	deck_power_point = 0
	for d in deck.cards:
		deck_list.add_child(create_draggable_item(d))
		deck_power_point += Global.card_list.get_card_data(d).power
	deck_power.text = DECK_POWER_TEXT % deck_power_point

	primary_color_button.color = deck.primary_color
	secondary_color_button.color = deck.secondary_color
	primary_color = deck.primary_color
	secondary_color = deck.secondary_color

	save_button.disabled = false


func get_texture(id : int):
	if not card_textures.has(id):
		var data := Global.card_list.get_card_data(id)
		var texture := CARD_TEXTURE.instantiate()
		add_child(texture)
		texture.initialize(data,Color.WHITE,null,false)
		card_textures[id] = texture.get_texture()
	return card_textures[id]


func initialize_pack_card_list(index : int):
	for c in pack_list.get_children():
		pack_list.remove_child(c)
		c.queue_free()

	var list : PackedInt32Array = pack_select_list[index]
	
	for i in list:
		pack_list.add_child(create_draggable_item(i))

func create_draggable_item(id : int) -> TextureRect:
	var item := DRAGGABLE_ITEM.instantiate()
	item.texture = get_texture(id)
	item.drag_start.connect(on_drag_start)
	item.dragging.connect(on_dragging)
	item.dropped.connect(on_dropped)
	item.set_meta("card_id",id)
	return item
	

func _on_item_list_item_selected(index):
	initialize_pack_card_list(index)


func on_drag_start(_self : Control,_pos : Vector2):
	mover.texture = _self.texture
	mover.show()
	mover.global_position = _self.global_position + _pos - mover.size / 2
	_self.modulate.a = 0.5
	
func on_dragging(_self : Control,_relative_pos : Vector2,_start_pos : Vector2):
	mover.global_position = _self.global_position + _start_pos + _relative_pos - mover.size / 2

	var point := _self.global_position + _start_pos + _relative_pos
	var rect := deck_list.get_global_rect()
	if deck_list.get_children().has(_self):
		if rect.has_point(point):
			mover.modulate.a = 1.0
		else:
			mover.modulate.a = 0.5
	else:
		if deck_list.get_child_count() < 6:
			mover.modulate.a = 1.0
		else:
			mover.modulate.a = 0.5


func on_dropped(_self : Control,_relative_pos : Vector2,_start_pos : Vector2):
	var point := _self.global_position + _start_pos + _relative_pos
	var rect := deck_list.get_global_rect()
	if deck_list.get_children().has(_self):
		if rect.has_point(point):
			var x := floori((point.x - rect.position.x) / (rect.size.x / 2))
			var y := floori((point.y - rect.position.y) / (rect.size.y / 3))
			var move := clampi(x + y * 2,0,deck_list.get_child_count())
			deck_list.move_child(_self,move)
		else:
			var id : int = _self.get_meta("card_id")
			deck_power_point -= Global.card_list.get_card_data(id).power
			deck_power.text = DECK_POWER_TEXT % deck_power_point
			deck_list.remove_child(_self)
			_self.queue_free()
	else:
		if rect.has_point(point):
			if deck_list.get_child_count() < 6:
				var id : int = _self.get_meta("card_id")
				var item := create_draggable_item(id)
				deck_list.add_child(item)
				var x := floori((point.x - rect.position.x) / (rect.size.x / 2))
				var y := floori((point.y - rect.position.y) / (rect.size.y / 3))
				var move := clampi(x + y * 2,0,deck_list.get_child_count())
				deck_list.move_child(item,move)
				deck_power_point += Global.card_list.get_card_data(id).power
				deck_power.text = DECK_POWER_TEXT % deck_power_point
	mover.hide()
	_self.modulate.a = 1.0
	
	if deck_list.get_child_count() != 6 or deck_power_point < 15:
		save_button.disabled = true
	else:
		save_button.disabled = false



func _on_back_button_pressed():
	back_button_pressed.emit()


func _on_save_button_pressed():
	if deck_list.get_child_count() != 6 or deck_power_point < 15:
		return
	
	var cards : Array[int] = []
	for c in deck_list.get_children():
		cards.append(c.get_meta("card_id"))
	var p_color : Color = primary_color_button.color
	var s_color : Color = secondary_color_button.color
	var deck := Deck.new(deck_name.text,cards,p_color,s_color)
	request_save.emit(deck)



func _on_primary_color_color_changed(color):
	if ColorDistance.near_color(color,secondary_color):
		if primary_color_button.color != primary_color:
			primary_color_button.color = primary_color
	else:
		primary_color = color


func _on_secondary_color_color_changed(color):
	if ColorDistance.near_color(color,primary_color):
		if secondary_color_button.color != secondary_color:
			secondary_color_button.color = secondary_color
	else:
		secondary_color = color
