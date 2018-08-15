extends Spatial

# If multiple players get on one space, this array decides the translation of each
const PLAYER_TRANSLATION = [Vector3(0, 0.25, -0.75), Vector3(0.75, 0.25, 0), Vector3(0, 0.25, 0.75), Vector3(-0.75, 0.25, 0)]
const EMPTY_SPACE_PLAYER_TRANSLATION = Vector3(0, 0.25, 0)

var players = null # Array containing the player nodes
var player_turn = 1 # Keeps track of whose turn it is
var nodes = null # Array containing the node nodes
var winner = null

var camera_focus = null

func _ready():
	randomize()
	nodes = get_tree().get_nodes_in_group("nodes")
	
	# Give each player a unique id
	var i = 1
	
	players = get_tree().get_nodes_in_group("players")
	for p in players:
		p.player_id = i
		i += 1
	
	camera_focus = players[0]
	$"/root/Global".load_board_state()
	
	# Initialize GUI
	$Screen/Turn.text = "Turn: " + var2str($"/root/Global".turn)
	$Screen/Dice.text = "Roll " + players[0].player_name + "!"
	
	_update_player_info()
	
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

func _unhandled_input(event):
	if(event.is_action_pressed("player"+var2str(player_turn)+"_ok")):
		_on_Roll_pressed()

func get_players_on_space(space):
	var num = 0
	for player in players:
		if(player.space == space):
			num += 1
	
	return num

func update_space(space):
	var num  = 0
	var max_num = get_players_on_space(space)
	for player in players:
		if(player.space == space):
			var translation = EMPTY_SPACE_PLAYER_TRANSLATION
			if max_num > 1:
				translation = PLAYER_TRANSLATION[num]
			player.destination.append(nodes[player.space - 1].translation + translation)
			num += 1

func _on_Roll_pressed():
	if winner != null:
		return
	
	if player_turn <= players.size():
		var player = players[player_turn - 1]
		camera_focus = player
		
		var dice = (randi() % 6) + 1 # Random number between 1 & 6
		
		# Adds each animation step to the player_board.gd script
		# The step to the last space is added during update_space(player.spce)
		for i in range(dice - 1):
			var players_on_space = get_players_on_space(player.space + i + 1)
			translation = EMPTY_SPACE_PLAYER_TRANSLATION
			if players_on_space > 0:
				translation = PLAYER_TRANSLATION[players_on_space]
			player.destination.append(nodes[(player.space + i) % nodes.size()].translation + translation)
		
		#self.translation = player.translation - Vector3(0, 3, 0)
		var previous_space = player.space
		player.space = (player.space + dice) # Keep track of which space the player is standing on
		if(player.space > nodes.size()):
			player.space = player.space % (nodes.size() + 1) + 1
		
		# Lose cookies if you land on red space
		if nodes[player.space -1].red:
			player.cookies -= 3
			if player.cookies < 0:
				player.cookies = 0
			_update_player_info()
			
		# Reposition figures
		update_space(previous_space)
		update_space(player.space)
		$Screen/Dice.text = player.name + " rolled: " + var2str(dice) # Show which number was rolled
	else:
		# All players have had their turn, goto mini-game
		$"/root/Global".turn += 1
		$"/root/Global".goto_minigame()
	player_turn += 1

func _process(delta):
	if(camera_focus != null):
		self.translation = camera_focus.translation

# Function that updates the player info shown in the GUI
func _update_player_info():
	var i = 1
	
	for p in players:
		var info = get_node("Screen/PlayerInfo" + var2str(i))
		info.get_node("Player").text = p.player_name
		info.get_node("Cookies/Amount").text = var2str(p.cookies)
		info.get_node("Cakes/Amount").text = var2str(p.cakes)
		i += 1