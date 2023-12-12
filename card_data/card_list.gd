
class_name CardList


class CardData:
	var id : int
	var power : int
	var arrows : PackedInt32Array
	var illust : String
	var others : String

class Pack:
	var name : String
	var include_ids : PackedInt32Array


func get_card_data(id : int) -> CardData:
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

const PACK_LIST := """
スターターセット＜001-012＞​​	1,2,3,4,5,6,7,8,9,10,11,12
タコス屋ブレイズコラボ＜013-016＞	13,14,15,16
"""

var card_list : Array[CardData] = []
var pack_list : Array[Pack] = []

func _init():
	var lines := CARD_LIST.split("\n",false)
	card_list.resize(lines.size() + 1)
	for l in lines:
		var columns := l.split("\t")
		var card_data := CardData.new()
		card_data.id = columns[0].to_int()
		card_data.power = columns[1].to_int()
		card_data.arrows.resize(8)
		var arrows := columns[2].split(",")
		for i in 8:
			card_data.arrows[i] = arrows[i].to_int()
		card_data.illust = columns[3]
		card_data.others = columns[4]
		card_list[card_data.id] = card_data
	
	lines = PACK_LIST.split("\n",false)
	for l in lines:
		var columns := l.split("\t")
		var pack := Pack.new()
		pack.name = columns[0]
		var ids := columns[1].split(",")
		pack.include_ids.resize(ids.size())
		for i in ids.size():
			pack.include_ids[i] = ids[i].to_int()
		pack_list.append(pack)
		
	
