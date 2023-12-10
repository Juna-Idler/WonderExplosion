extends Control


# Called when the node enters the scene tree for the first time.
func _ready():
	pass # Replace with function body.



func initialize(card_data : CardList.CardData,color : Color,texture : Texture2D,opponent : bool):
	%LabelPower.text = str(card_data.power)
	
	var leak_labels := [%Label2,%Label3,%Label5,%Label8,%Label7,%Label6,%Label4,%Label1]
	for i in 8:
		var l := card_data.arrows[i]
		if l > 0:
			leak_labels[i].text = "+%d" % l
		elif l < 0:
			leak_labels[i].text = str(l)
		else:
			leak_labels[i].text = ""
		#if opponent:
			#leak_labels[i].rotation = PI
	%ColorRect.color = color
	if texture:
		%TextureRect.texture = texture

	#if opponent:
		#%LabelPower.rotation = PI
		#%LabelSpell.rotation = PI

