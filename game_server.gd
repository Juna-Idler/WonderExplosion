
class_name IGameServer


class FirstData:
	var my_deck : Array[int] # card id
	var my_hand : Array[int] # deck index

	var rival_deck_count : int #デッキの総数(通常6)
	var rival_hand_count : int #手札の数(通常3)
	
	#先攻(1)か後攻(2)か
	var player_number : int



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


	#バトルの結果
	class Battle:
		var card : int #もともとフィールドにあったカードのID
		var result : int #バトル結果 1:turn player win , -1:turn player lose , 0:draw

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
			
		var other : OtherExplosion = null	#通常はnull




func _send_ready_async() -> FirstData:
	@warning_ignore("redundant_await")
	return await null

func _play_async(_deck_index : int,_position : int) -> Result:
	@warning_ignore("redundant_await")
	return await null

func _wait_async() -> Result:
	@warning_ignore("redundant_await")
	return await null
