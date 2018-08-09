extends Spatial

var players = null # Array containing the player nodes
var player_turn = 1 # Keeps track of whose turn it is
var nodes = null # Array containing the node nodes
var has_rolled = false
var winner = null

func _ready():
	randomize()
	nodes = get_tree().get_nodes_in_group("nodes")
	
	# Give each player a unique id
	var i = 1
	
	players = get_tree().get_nodes_in_group("players")
	for p in players:
		p.player_id = i
		i += 1
	
	$"/root/Global".load_board_state()
	
	# Initialize GUI
	$Screen/Turn.text = "Turn: " + var2str($"/root/Global".turn)
	
	i = 1
	
	# Retrieve all information that will be displayed for players
	for p in players:
		var info = get_node("Screen/PlayerInfo" + var2str(i))
		info.get_node("Player").text = p.player_name
		info.get_node("Cookies").text = "Cookies: " + var2str(p.cookies)
		info.get_node("Cakes").text = "Cake: " + var2str(p.cakes)
		i += 1
	
	$Screen/Dice.text = "Roll " + players[0].player_name + "!"
	
	if $"/root/Global".turn > $"/root/Global".max_turns:
		var message = ""
		
		for p in players:
			if winner == null:
				winner = p
			else:
				if p.cakes > winner.cakes:
					winner = p
					message = winner.player_name
				elif p.cakes == winner.cakes:
					if p.cookies > winner.cookies:
						winner = p
						message = winner.player_name
					elif p.cookies == winner.cookies:
						message = "Draw!"
		
		if message != "Draw!":
			message = "The winner is " + winner.player_name
		
		$Screen/Turn.text = message
		$Screen/Roll.disabled = true
		$Screen/Dice.text = "Game over!"

func _on_Roll_pressed():
	if winner != null:
		return
	
	if player_turn <= players.size():
		var player = players[player_turn - 1]
		
		if has_rolled:
			has_rolled = false
			$Screen/Dice.text = "Roll " + player.player_name + "!"
			self.translation = player.translation
			return
		
		var dice = (randi() % 6) + 1 # Random number between 1 & 6
		
		# If the player will exceed the number of spaces on the board then loop
		if (player.space + dice) <= nodes.size():
			player.translation = nodes[player.space + dice - 1].translation + Vector3(0, 3, 0)
			self.translation = player.translation - Vector3(0, 3, 0)
			player.space += dice # Keep track of which space the player is standing on
		else:
			var space = (player.space + dice) - nodes.size()
			player.translation = nodes[space].translation + Vector3(0, 3, 0)
			self.translation = player.translation - Vector3(0, 3, 0)
			player.space = space # Keep track of which space the player is standing on
		
		$Screen/Dice.text = player.name + " rolled: " + var2str(dice) # Show which number was rolled
		has_rolled = true
	else:
		# All players have had their turn, goto mini-game
		$"/root/Global".turn += 1
		$"/root/Global".goto_minigame()
	player_turn += 1