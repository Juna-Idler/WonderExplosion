
class_name IGameServer


class FirstData:
	var my_name : String
	var rival_name : String
	
	var my_deck : Array[int] # card id
	var my_hand : Array[int] # deck index

	var rival_deck_count : int #デッキの総数(通常6)
	var rival_hand_count : int #手札の数(通常3)

	var my_colors : Array[Color]
	var rival_colors : Array[Color]

	#先攻(1)か後攻(2)か
	var player_number : int

	func serialize() -> Dictionary:
		return {
			"mn":my_name,
			"rn":rival_name,
			"md":my_deck,
			"mh":my_hand,
			"rd":rival_deck_count,
			"rh":rival_hand_count,
			"mc":[my_colors[0].to_html(false),my_colors[1].to_html(false)],
			"rc":[rival_colors[0].to_html(false),rival_colors[1].to_html(false)],
			"pn":player_number,
		}
	static func deserialize(dic : Dictionary) -> FirstData:
		var fd := FirstData.new()
		fd.my_name = dic["mn"]
		fd.rival_name = dic["rn"]
		fd.my_deck.assign(dic["md"])
		fd.my_hand.assign(dic["mh"])
		fd.rival_deck_count = dic["rd"]
		fd.rival_hand_count = dic["rh"]
		fd.my_colors = [Color(dic["mc"][0]),Color(dic["mc"][1])]
		fd.rival_colors = [Color(dic["rc"][0]),Color(dic["rc"][1])]
		fd.player_number = dic["pn"]
		return fd


class Result:
	var turn_count : int	#ターン数
	var player : int	#このプレイをしたプレイヤーナンバー
	var position : int	#プレイしたフィールドの位置
	var play_card : int	#プレイしたカードのID setした場合は-1
	
	#バトルが発生しなければnull
	var battle : Battle = null
	#起爆が発生しなければnull
	var explosion : Explosion = null

	#次のプレイのプレイヤー ゲーム終了なら0
	var next_player : int
	
	#setをした場合、ターンプレイヤーにだけそのカードのIDをエコーバックする
	var closed_play_card : int
	#next_playerがドローしたカードのデッキindex（自分のドローでない場合は-1がドローした枚数分だけ入る）
	var draw_cards : Array[int] = []

	func serialize() -> Dictionary:
		return {
			"t":turn_count,
			"n":player,
			"p":position,
			"c":play_card,
			"b":battle.serialize() if battle else {},
			"e":explosion.serialize() if explosion else {},
			"np":next_player,
			"cc":closed_play_card,
			"d":draw_cards,
		}
	static func deserialize(dic : Dictionary) -> Result:
		if dic.is_empty():
			return null
		var r := Result.new()
		r.turn_count = dic["t"]
		r.player = dic["n"]
		r.position = dic["p"]
		r.play_card = dic["c"]
		r.battle = Battle.deserialize(dic["b"])
		r.explosion = Explosion.deserialize(dic["e"])
		r.next_player = dic["np"]
		r.closed_play_card = dic["cc"]
		r.draw_cards.assign(dic["d"])
		return r


	#バトルの結果
	class Battle:
		var card : int #もともとフィールドにあったカードのID
		var result : int #バトル結果 1:turn player win , -1:turn player lose , 0:draw
		
		func serialize() -> Dictionary:
			return {
				"c":card,
				"r":result
			}
		static func deserialize(dic : Dictionary) -> Battle:
			if dic.is_empty():
				return null
			var b := Battle.new()
			b.card = dic["c"]
			b.result = dic["r"]
			return b

	#起爆データ
	class Explosion:
		var positions : Array[int] = []	#起爆したカードの位置
		var cards : Array[int] = []	#起爆したカードのID
		var power : int = 0	#起爆の総合威力
		
		#盤面が埋まった時、プレイしていない方の起爆データ
		class OtherExplosion:
			var positions : Array[int] = []
			var cards : Array[int] = []
			var power : int = 0
			
			func serialize() -> Dictionary:
				return {
					"p":positions,
					"c":cards,
					"d":power
				}
			static func deserialize(dic : Dictionary) -> OtherExplosion:
				if dic.is_empty():
					return null
				var o := OtherExplosion.new()
				o.positions.assign(dic["p"])
				o.cards.assign(dic["c"])
				o.power = dic["d"]
				return o

		var other : OtherExplosion = null	#通常はnull

		func serialize() -> Dictionary:
			return {
				"p":positions,
				"c":cards,
				"d":power,
				"o":other.serialize() if other else {}
			}
		static func deserialize(dic : Dictionary) -> Explosion:
			if dic.is_empty():
				return null
			var e := Explosion.new()
			e.positions.assign(dic["p"])
			e.cards.assign(dic["c"])
			e.power = dic["d"]
			e.other = OtherExplosion.deserialize(dic["o"])
			return e
			


func _send_ready_async() -> FirstData:
	@warning_ignore("redundant_await")
	return await null

func _play_async(_deck_index : int,_position : int) -> Result:
	@warning_ignore("redundant_await")
	return await null

func _wait_async() -> Result:
	@warning_ignore("redundant_await")
	return await null
