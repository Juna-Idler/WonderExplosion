extends Panel

const DRAGGABLE_ITEM = preload("res://build/draggable_item.tscn")
const CARD_TEXTURE = preload("res://match/card_texture.tscn")

@onready var item_list : ItemList = %ItemList

var card_textures : Dictionary = {}

var pack_select_list : Dictionary = {}

@onready var pack_list = %PackList
@onready var deck_list : GridContainer = %DeckList

@onready var mover : TextureRect = %Mover


# Called when the node enters the scene tree for the first time.
func _ready():
	var deck := Deck.new("no name",[1,2,3,4,5,6],Color.BLUE,Color.RED)
	initialize(deck)
	pass # Replace with function body.


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(_delta):
	pass

func initialize(deck : Deck):
	var card_list := Global.card_list.card_list.duplicate()
	card_list.pop_front()
	var index := item_list.add_item("ALL")
	pack_select_list[index] = PackedInt32Array(card_list.map(func(v:CardList.CardData):return v.id))
	for p in Global.card_list.pack_list:
		var i := item_list.add_item(p.name)
		pack_select_list[i] = p.include_ids
	item_list.select(1)
	initialize_pack_card_list(1)

	for d in deck.cards:
		deck_list.add_child(create_draggable_item(d))


func get_texture(id : int):
	if not card_textures.has(id):
		var data := Global.card_list.get_card_data(id)
		var card_data := Mechanics.CardData.new(data.id,data.power,data.arrows)
		var texture := CARD_TEXTURE.instantiate()
		add_child(texture)
		texture.initialize(card_data,Color.WHITE,null,false)
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
			deck_list.remove_child(_self)
			_self.queue_free()
		pass
	else:
		if rect.has_point(point):
			if deck_list.get_child_count() < 6:
				var item := create_draggable_item(_self.get_meta("card_id"))
				deck_list.add_child(item)
				var x := floori((point.x - rect.position.x) / (rect.size.x / 2))
				var y := floori((point.y - rect.position.y) / (rect.size.y / 3))
				var move := clampi(x + y * 2,0,deck_list.get_child_count())
				deck_list.move_child(item,move)
				
		pass
	mover.hide()
	_self.modulate.a = 1.0
	pass
