extends Spatial

var end_timer = false

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
	end_timer = true
	
	$Overlay/Label.text = "Stop!"
	$Overlay/AnimationPlayer.play("reset")
	
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
	if not end_timer:
		$Overlay/Label.text = "Go!"
		$Overlay/AnimationPlayer.play("fadeout")
		
		for i in range(num_players):
			next_action(i + 1)
	else:
		match Global.minigame_type:
			Global.MINIGAME_TYPES.FREE_FOR_ALL, Global.MINIGAME_TYPES.DUEL:
				var placement = []
				
				for i in range(num_players):
					placement.append(i + 1)
				
				var players = get_tree().get_nodes_in_group("players")
				
				placement.sort_custom(Sorter.new(players), "_sort")
				for i in range(placement.size()):
					placement[i] = players[placement[i] - 1].player_id
				
				Global.goto_board(placement)
			Global.MINIGAME_TYPES.TWO_VS_TWO:
				# Find the team of the player that won
				for p in get_tree().get_nodes_in_group("players"):
					if p.presses == p.NEEDED_BUTTON_PRESSES:
						for team_id in range(Global.minigame_teams.size()):
							for player_id in Global.minigame_teams[team_id]:
								if p.player_id == player_id:
									Global.goto_board(team_id)
