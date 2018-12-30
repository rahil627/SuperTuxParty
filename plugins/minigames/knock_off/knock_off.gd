extends Spatial

var losses = 0 # Number of players that have been knocked-out
var placement# Placements, is filled with player id in order. Index 0 is first place
var timer_end = 4 # How long the winning message will be shown before exiting
var timer_end_start = false # When to start the end timer

var winner_team

func _ready():
	$Environment/Screen/Message.hide()
	
	if Global.minigame_type == Global.MINIGAME_TYPES.DUEL:
		placement = [0, 0]
	else:
		placement = [0, 0, 0, 0]
	
	var i = 1
	for team_id in range(Global.minigame_teams.size()):
		for player in Global.minigame_teams[team_id]:
			get_node("Player"+var2str(i)).team = team_id
			i += 1

func win_condition(players):
	if Global.minigame_type == Global.MINIGAME_TYPES.FREE_FOR_ALL:
		return players.size() <= 1
	else:
		var team
		for p in get_tree().get_nodes_in_group("players"):
			if team != null and p.team != team:
				return false
			team = p.team
		
		return true
	

func _process(delta):
	var players = get_tree().get_nodes_in_group("players")
	for p in players:
		if p.translation.y < -10:
			losses += 1
			placement[placement.size() - losses] = p.player_id # Assign placement before deleting player
			if losses == placement.size():
				winner_team = p.team
			p.queue_free()
	
	if win_condition(players) and not timer_end_start:
		# If the last player has not died yet, put him as the winner
		if players.size() == 1:
			placement[0] = players[0].player_id
			players[0].winner = true
		
		if not players.empty():
			winner_team = players[0].team
		timer_end_start = true
		
		match Global.minigame_type:
			Global.MINIGAME_TYPES.FREE_FOR_ALL, Global.MINIGAME_TYPES.DUEL:
				for p in Global.players:
					if p.player_id == placement[0]:
						$Environment/Screen/Message.text = p.player_name + " wins!"
			Global.MINIGAME_TYPES.TWO_VS_TWO:
				$Environment/Screen/Message.text = "Team %d wins!" % (winner_team + 1)
		
		$Environment/Screen/Message.show()
	
	if timer_end_start:
		timer_end -= delta
		if timer_end <= 0:
			match Global.minigame_type:
				Global.MINIGAME_TYPES.DUEL, Global.MINIGAME_TYPES.FREE_FOR_ALL:
					Global.goto_board(placement)
				Global.MINIGAME_TYPES.TWO_VS_TWO:
					Global.goto_board(winner_team)