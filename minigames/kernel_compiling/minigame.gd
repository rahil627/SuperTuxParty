extends Spatial

var end_timer = false

func get_player(i):
	return get_node("Player" + var2str(i))

func _ready():
	for i in range(Global.amount_of_players):
		get_player(i + 1).idx = i+1

func next_action(i):
	var player = get_player(i)
	var action = "player" + var2str(i) + "_" + player.ACTIONS[randi() % player.ACTIONS.size()]
	player.next_action = action
	get_node("ControlView" + var2str(i)).display_action(action)

func stop_game():
	end_timer = true
	
	$Overlay/Label.text = "Stop!"
	$Overlay/AnimationPlayer.play("reset")
	
	for i in range(Global.amount_of_players):
		get_player(i + 1).next_action = null
		get_node("ControlView" + var2str(i + 1)).clear_display()

	
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
		
		for i in range(Global.amount_of_players):
			next_action(i + 1)
	else:
		var placement = []
		
		for i in range(Global.amount_of_players):
			placement.append(i + 1)
		
		placement.sort_custom(Sorter.new(get_tree().get_nodes_in_group("players")), "_sort")
		Global.goto_board(placement)
