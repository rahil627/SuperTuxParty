extends Spatial

# If multiple players get on one space, this array decides the translation of each
const PLAYER_TRANSLATION = [Vector3(0, 0.25, -0.75), Vector3(0.75, 0.25, 0), Vector3(0, 0.25, 0.75), Vector3(-0.75, 0.25, 0)]
const EMPTY_SPACE_PLAYER_TRANSLATION = Vector3(0, 0.25, 0)
const CAMERA_SPEED = 6

var players = null # Array containing the player nodes
var player_turn = 1 # Keeps track of whose turn it is
var nodes = null # Array containing the node nodes
var winner = null

var camera_focus = null
var end_turn = true

func _ready():
	nodes = get_tree().get_nodes_in_group("nodes")
	var cake_nodes = get_tree().get_nodes_in_group("cake_nodes")
	
	# Randomly place cake spot on board
	if cake_nodes.size() > 0:
		var cake_node = cake_nodes[randi() % cake_nodes.size()]
		cake_node.cake = true
		cake_node.get_node("Cake").visible = true
	
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
	
	update_player_info()
	
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
			var offset = EMPTY_SPACE_PLAYER_TRANSLATION
			if max_num > 1:
				offset = PLAYER_TRANSLATION[num]
			player.destination.append(nodes[player.space - 1].translation + offset)
			num += 1

func _on_Roll_pressed():
	$Screen/GetCake.hide()
	end_turn = true
	
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
			var offset = EMPTY_SPACE_PLAYER_TRANSLATION
			if players_on_space > 0:
				offset = PLAYER_TRANSLATION[players_on_space]
			player.destination.append(nodes[(player.space + i) % nodes.size()].translation + offset)
			
			# If player passes a cake-spot
			if nodes[(player.space + i)].cake && player.cookies >= 30:
				$Screen/GetCake.show()
				end_turn = false
		
		var previous_space = player.space
		
		# Keep track of which space the player is standing on
		player.space = (player.space + dice) 
		if(player.space > nodes.size()):
			player.space = player.space % (nodes.size() + 1) + 1
		
		# Lose cookies if you land on red space
		if nodes[player.space -1].red:
			player.cookies -= 3
			if player.cookies < 0:
				player.cookies = 0
		elif nodes[player.space -1].green:
			if get_parent().has_method("fire_event"):
				get_parent().fire_event()
		else:
			player.cookies += 3
		
		# Reposition figures
		update_space(previous_space)
		update_space(player.space)
		
		# Show which number was rolled
		$Screen/Dice.text = player.player_name + " rolled: " + var2str(dice) 
	else:
		# All players have had their turn, goto mini-game
		$"/root/Global".turn += 1
		$"/root/Global".goto_minigame()
	
	player_turn += 1
	
	if player_turn > players.size():
		$Screen/Roll.text = "Minigame"

func _process(delta):
	if camera_focus != null:
		var dir = camera_focus.translation - self.translation
		if(dir.length() > 0.01):
			self.translation += (CAMERA_SPEED * dir.length()) * dir.normalized() * delta
	
	# Automatically switch to next player when current player has finished moving
	if player_turn - 2 >= 0 && player_turn - 1 < $"/root/Global".amount_of_players:
		var player = players[player_turn - 2]
		if camera_focus == player:
			if player.destination.size() == 0 && end_turn:
				camera_focus = players[player_turn - 1]

# Function that updates the player info shown in the GUI
func update_player_info():
	var i = 1
	
	for p in players:
		var info = get_node("Screen/PlayerInfo" + var2str(i))
		info.get_node("Player").text = p.player_name
		
		if p.cookies_gui == p.cookies:
			info.get_node("Cookies/Amount").text = var2str(p.cookies)
		elif p.destination.size() > 0:
			info.get_node("Cookies/Amount").text = var2str(p.cookies_gui)
		elif p.cookies_gui > p.cookies:
			info.get_node("Cookies/Amount").text = "-" + var2str(p.cookies_gui - p.cookies) + "  " + var2str(p.cookies_gui)
		else:
			info.get_node("Cookies/Amount").text = "+" + var2str(p.cookies - p.cookies_gui) + "  " + var2str(p.cookies_gui)
		
		info.get_node("Cakes/Amount").text = var2str(p.cakes)
		i += 1

func _on_GetCake_pressed():
	var player = players[player_turn - 2]
	player.cookies -= 30
	player.cakes += 1
	
	if player.cookies < 30:
		$Screen/GetCake.hide()
