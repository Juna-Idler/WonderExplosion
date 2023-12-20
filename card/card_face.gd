extends Control


# Called when the node enters the scene tree for the first time.
func _ready():
	pass # Replace with function body.



func initialize(card_data : CardList.CardData):
	var image_path := "res://card_images/%03d.jpg" % card_data.id
	var image := load(image_path)
	if image:
		%TextureRect.texture = image
		%Power.hide()
	else:
		%Power.show()
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


