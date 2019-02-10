extends Spatial

const LAVA_RISE_SPEED = 0.25

var winners = [0, 0, 0, 0]
var num_players_alive = 4
var num_players_finished = 0

func process_stage(stage):
	var index = (randi() % stage.get_child_count())
	stage.get_child(index).can_be_opened = false

func _ready():
	process_stage($Stage1)
	process_stage($Stage2)
	process_stage($Stage3)
	
	if Global.minigame_type == Global.MINIGAME_TYPES.DUEL:
		winners = [0, 0]
		num_players_alive = 2


func _process(delta):
	var min_progress = null
	
	for player in get_tree().get_nodes_in_group("players"):
		if not player.is_dead() and (min_progress == null or player.translation.z < min_progress.z):
			min_progress = player.translation
	
	if min_progress != null:
		$Camera.translation +=  (Vector3(0, min_progress.y, min_progress.z) + Vector3(0, 3, -4) - $Camera.translation) * delta
	
	$Lava.translation += Vector3(0, 1, 0) * delta * LAVA_RISE_SPEED


func _on_Lava_body_entered(body):
	if body.is_in_group("players"):
		if not body.is_dead():
			body.die()
			
			winners[num_players_alive - 1] = body.player_id
			num_players_alive -= 1
			
			if num_players_alive == 1:
				for player in get_tree().get_nodes_in_group("players"):
					if not player.is_dead() and not player.has_finished:
						player.die()
						winners[num_players_alive - 1] = player.player_id
						num_players_alive -= 1
				end_game()
	elif body.is_in_group("door"):
		body.destroy()


func _on_Finish_body_entered(body):
	if body.is_in_group("players"):
		winners[num_players_finished] = body.player_id
		num_players_finished += 1
		body.has_finished = true
		body.die()
		
		if num_players_alive == num_players_finished:
			end_game()

func end_game():
	$Screen/Label.show()
	$EndTimer.start()

func _on_EndTimer_timeout():
	if Global.minigame_type == Global.MINIGAME_TYPES.DUEL or Global.minigame_type == Global.MINIGAME_TYPES.FREE_FOR_ALL:
		Global.minigame_win_by_position(winners)
	else:
		Global.minigame_team_win_by_player(winners[0])
