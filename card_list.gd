

func get_card_data(id : int) -> Mechanics.CardData:
	return card_list[id]


const CARD_LIST := """
1	0	0,0,0,0,0,0,0,0	
2	1	0,0,0,1,0,0,0,0	
3	2	0,1,0,0,0,1,0,0	
4	3	0,0,0,0,0,3,0,0	
5	4	0,1,0,0,0,1,2,0	
6	5	0,0,0,0,0,0,0,5	
7	0	0,0,0,0,0,0,0,0	
8	1	0,0,0,0,0,1,0,0	
9	2	0,0,0,1,0,0,0,1	
10	3	0,0,0,0,0,0,1,2	
11	4	2,0,2,0,0,0,0,0	
12	5	1,1,0,1,0,1,0,1	
13	1	0,0,1,0,0,0,0,0	
14	2	0,0,1,0,0,0,1,0	
15	3	1,0,0,1,0,1,0,0	
16	4	1,2,1,0,0,0,0,0	
"""

var card_list : Array[Mechanics.CardData] = []

func _init():
	var lines := CARD_LIST.split("\n",false)
	card_list.resize(lines.size() + 1)
	for l in lines:
		var columns := l.split("\t")
		var card_data := Mechanics.CardData.new()
		card_data.id = columns[0].to_int()
		card_data.power = columns[1].to_int()
		card_data.leaks.resize(8)
		var arrows := columns[2].split(",")
		for i in 8:
			card_data.leaks[i] = arrows[i].to_int()
		card_data.spell = columns[3]
		card_list[card_data.id] = card_data
	
