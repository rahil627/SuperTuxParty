extends Spatial

onready var num_players = get_tree().get_nodes_in_group("players").size()

func get_player(i):
	return get_node("Player" + var2str(i))

func _ready():
	for i in range(num_players):
		get_player(i + 1).idx = i+1

func next_action(i):
	var player = get_player(i)
	var action = "player" + var2str(player.player_id) + "_" + player.ACTIONS[randi() % player.ACTIONS.size()]
	player.next_action = action
	player.get_node("Screen/ControlView").display_action(action)

func stop_game():
	for i in range(num_players):
		var player = get_player(i + 1)
		player.next_action = null
		player.get_node("Screen/ControlView").clear_display()

	
	$Timer.start()

class Sorter:
	var players
	
	func _init(players):
		self.players = players
	
	func _sort(a, b):
		return players[a - 1].presses > players[b - 1].presses

func _on_Timer_timeout():
	match Global.minigame_type:
		Global.MINIGAME_TYPES.FREE_FOR_ALL, Global.MINIGAME_TYPES.DUEL:
			var points = []
			
			for p in get_tree().get_nodes_in_group("players"):
				points.append(p.presses)
			
			Global.minigame_win_by_points(points)
		Global.MINIGAME_TYPES.TWO_VS_TWO:
			# Find the team of the player that won
			for p in get_tree().get_nodes_in_group("players"):
				if p.presses == p.NEEDED_BUTTON_PRESSES:
					Global.minigame_team_win_by_player(p.player_id)

func _on_Countdown_finish():
	for i in range(num_players):
		next_action(i + 1)
