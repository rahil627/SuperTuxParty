tool
extends Spatial

# If multiple players get on one space, this array decides the translation of each
const PLAYER_TRANSLATION = [Vector3(0, 0.25, -0.75), Vector3(0.75, 0.25, 0), Vector3(0, 0.25, 0.75), Vector3(-0.75, 0.25, 0)]
const EMPTY_SPACE_PLAYER_TRANSLATION = Vector3(0, 0.25, 0)
const CAMERA_SPEED = 6

var COOKIES_FOR_CAKE = 30

const NODE = preload("res://boards/node/node.gd")

var players = null # Array containing the player nodes
var player_turn = 1 # Keeps track of whose turn it is
var winner = null

var camera_focus = null
var end_turn = true

enum EDITOR_NODE_LINKING_DISPLAY { DISABLED = 0, NEXT_NODES = 1, PREV_NODES = 2, ALL = 3 }

# Path to the node, where Players start
export(NodePath) var start_node
export(EDITOR_NODE_LINKING_DISPLAY) var show_linking_type = ALL

# Stores the amount of steps the current player still needs to take, to complete his roll
# Used when the player movement is interrupted because of a cake spot
var steps_remaining = 0
# Stores the value of steps that still need to be performed after a dice roll
# Used for display
var step_count = 0

# Store if the splash for a character was already shown
var splash_ended = false
# Flag that indicates if the input needs to wait for the animation to finish
var wait_for_animation = false

func check_winner():
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

func _ready():
	# Make it easier for nodes to find the controller
	add_to_group("Controller")
	
	if Engine.editor_hint:
		return
	
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
		if p.space == null:
			p.space = get_node(start_node)
			p.translation = p.space.translation + PLAYER_TRANSLATION[i-2]
	
	camera_focus = players[0]
	$"/root/Global".load_board_state()
	
	if $"/root/Global".award == $"/root/Global".AWARD_T.winner_only:
		COOKIES_FOR_CAKE = 20
		$Screen/GetCake/Label.text = "Buy a cake for 20 cookies"
	
	# Initialize GUI
	$Screen/Turn.text = "Turn: " + var2str($"/root/Global".turn)
	$Screen/Dice.text = "Roll " + players[0].player_name + "!"
	
	update_player_info()
	
	$Screen/Debug.setup()
	
	check_winner()
	
	# Show "your turn screen" for first player
	_on_Roll_pressed()

func _unhandled_input(event):
	if Engine.editor_hint:
		return
	
	if(event.is_action_pressed("player"+var2str(player_turn)+"_ok")):
		_on_Roll_pressed()
	elif event.is_action_pressed("debug"):
		$Screen/Debug.popup()

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
			player.destination.append(player.space.translation + offset)
			num += 1

func animation_ended(player_id):
	if player_id != player_turn - 1:
		return
	
	if end_turn:
		wait_for_animation = false
		_on_Roll_pressed()
	else:
		wait_for_animation = true
		$Screen/GetCake.show()

func animation_step(player_id):
	if player_id != player_turn - 1:
		return
	
	step_count -= 1
	if step_count > 0:
		$Screen/Stepcounter.text = var2str(step_count)
	else:
		$Screen/Stepcounter.text = ""

func _on_Roll_pressed():
	if wait_for_animation:
		return
	
	$Screen/GetCake.hide()
	
	if winner != null:
		return
	
	if splash_ended or player_turn > players.size():
		splash_ended = false
		roll()
	else:
		splash_ended = true
		var image = ResourceLoader.load($"/root/Global".character_loader.get_character_splash($"/root/Global".players[player_turn - 1].character)).get_data()
		image.resize(256, 256)
		
		$Screen/Splash/Background/Player.texture = ImageTexture.new()
		$Screen/Splash/Background/Player.texture.create_from_image(image)
		$Screen/Splash.play("show")

# Moves a player num spaces forward and stops when a cake spot is encoutered
func do_step(player, num):
	if num <= 0:
		animation_ended(player.player_id)
		return
	
	# Adds each animation step to the player_board.gd script
	# The step to the last space is added during update_space(player.space)
	var previous_space = player.space
	for i in range(num - 1):
		# TODO: enable multiple branches later on
		player.space = player.space.next[0]
		# If player passes a cake-spot
		if player.space.cake && player.cookies >= COOKIES_FOR_CAKE:
			end_turn = false
			
			steps_remaining = num - (i + 1)
			update_space(previous_space)
			update_space(player.space)
			return
		else:
			var players_on_space = get_players_on_space(player.space) - 1
			var offset = EMPTY_SPACE_PLAYER_TRANSLATION
			if players_on_space > 0:
				offset = PLAYER_TRANSLATION[players_on_space]
			player.destination.append(player.space.translation + offset)
	
	# TODO: enable multiple branches later on
	player.space = player.space.next[0]
	if player.space.cake && player.cookies >= COOKIES_FOR_CAKE:
		end_turn = false
		steps_remaining = 0
	
	# Reposition figures
	update_space(previous_space)
	update_space(player.space)
	
	# Lose cookies if you land on red space
	match player.space.type:
		NODE.RED:
			player.cookies -= 3
			if player.cookies < 0:
				player.cookies = 0
		NODE.GREEN:
			if get_parent().has_method("fire_event"):
				get_parent().fire_event(player, player.space)
		NODE.BLUE:
			player.cookies += 3

func roll():
	$Screen/Splash.play("hide")
	wait_for_animation = true
	end_turn = true
	
	if winner != null:
		return
	
	if player_turn <= players.size():
		var player = players[player_turn - 1]
		camera_focus = player
		
		var dice = (randi() % 6) + 1 # Random number between 1 & 6
		
		$Screen/Stepcounter.text = var2str(dice)
		step_count = dice
		
		do_step(player, dice)
		
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
	if Engine.editor_hint:
		return
	
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
	$Screen/GetCake.hide()
	$Screen/BuyCake.show()
	
	$Screen/BuyCake/HSlider.max_value = int(players[player_turn - 2].cookies / COOKIES_FOR_CAKE)
	$Screen/BuyCake/HSlider.value = $Screen/BuyCake/HSlider.max_value

func _on_GetCake_abort():
	var player = players[player_turn - 2]
	
	$Screen/GetCake.hide()
	end_turn = true
	do_step(player, steps_remaining)

func _on_Buy_pressed():
	var amount = int($Screen/BuyCake/HSlider.value)
	
	var player = players[player_turn - 2]
	player.cookies -= COOKIES_FOR_CAKE * amount
	player.cakes += amount
	
	$Screen/BuyCake.hide()
	end_turn = true
	do_step(player, steps_remaining)


func _on_Abort_pressed():
	$Screen/BuyCake.hide()
	$Screen/GetCake.show()


func _on_HSlider_value_changed(value):
	$Screen/BuyCake/Amount.text = "x" + var2str(int(value))
