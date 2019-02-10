extends Spatial

const MAX_KNOCKOUT = 3
var knocked_out = 0

var minigame_time = 20

var winner = null
var end_timer = false

func end_timer():
	end_timer = true
	$Screen/Label.show()
	$Timer.start()

func _process(delta):
	if not end_timer:
		minigame_time -= delta
		if minigame_time <= 0:
			minigame_time = 0
			winner = 0
			end_timer()
			
		$Screen/Time.text= var2str(stepify(minigame_time, 0.1))

func knockout(player):
	if winner != null:
		return
	
	if player.player_id == Global.minigame_teams[1][0]:
		winner = 0
		
		end_timer()
	else:
		knocked_out += 1
		if knocked_out == MAX_KNOCKOUT:
			winner = 1
			
			end_timer()

func _on_EndTimer_timeout():
	Global.minigame_team_win(winner)

func _on_Countdown_finish():
	$Screen/Time.show()
