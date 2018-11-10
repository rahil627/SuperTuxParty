extends Spatial

const MAX_KNOCKOUT = 3
var knocked_out = 0

var minigame_time = 20

var winner = null

var end_timer = false
var started = false

func _ready():
	$Timer.start()

func end_timer():
	$Screen/Label.text = "Finish!"
	$Screen/Label.show()
	end_timer = true
	$Timer.start()
	
	for p in get_tree().get_nodes_in_group("players"):
		p.state = p.PAUSED
		p.get_node("Model/AnimationPlayer").stop()

func _process(delta):
	if not started:
		$Screen/Time.text = var2str(stepify($Timer.time_left, 0.1))
	elif not end_timer:
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
	if end_timer:
		Global.goto_board(winner)
	else:
		$Screen/Label.text = "Go!"
		$Screen/AnimationPlayer.play("fadeout")
		for p in get_tree().get_nodes_in_group("players"):
			p.state = p.IDLE
		started = true
