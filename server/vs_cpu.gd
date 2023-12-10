

var processor : Mechanics


func initialize():
	var deck : Array[Mechanics.CardData] = []
	for i in 6:
		var card := Mechanics.CardData.new()
		card.id = i
		card.power = i
		card.spell = "w"
		card.leaks = []
		deck.append(card)
	processor = Mechanics.new()
	processor.initialize(deck,deck)
	




