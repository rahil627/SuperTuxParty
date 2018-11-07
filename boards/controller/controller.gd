extends Spatial

# If multiple players get on one space, this array decides the translation of each
const PLAYER_TRANSLATION = [Vector3(0, 0.25, -0.75), Vector3(0.75, 0.25, 0), Vector3(0, 0.25, 0.75), Vector3(-0.75, 0.25, 0)]
const EMPTY_SPACE_PLAYER_TRANSLATION = Vector3(0, 0.25, 0)
const CAMERA_SPEED = 6

const CONTROL_HELPER = preload("res://controlhelper.gd")
const NODE = preload("res://boards/node/node.gd")

var COOKIES_FOR_CAKE = 30

# Used internally for selecting a path on the board with buttons
var selected_id = -1

# Array containing the player nodes
var players = null 

# Keeps track of whose turn it is
var player_turn = 1 
var winner = null

var camera_focus = null
var end_turn = true

# Next node for player to go to when the player has chosen a path
var next_node = null

enum EDITOR_NODE_LINKING_DISPLAY { DISABLED = 0, NEXT_NODES = 1, PREV_NODES = 2, ALL = 3 }
enum TURN_ACTION {BUY_CAKE = 0, CHOOSE_PATH = 1, CHOOSE_OPPONENT}

# Path to the node, where Players start
export(NodePath) var start_node
export(EDITOR_NODE_LINKING_DISPLAY) var show_linking_type = ALL

# Stores the amount of steps the current player still needs to take, to complete his roll
# Used when the player movement is interrupted because of a cake spot
var steps_remaining = 0

# Stores the value of steps that still need to be performed after a dice roll
# Used for display
var step_count = 0

# Stores which action the player will perform when stopping during their turn
var do_action = TURN_ACTION.BUY_CAKE

# Store if the splash for a character was already shown
var splash_ended = false

# Flag that indicates if the input needs to wait for the animation to finish
var wait_for_animation = false

var current_minigame = null

func check_winner():
	if Global.turn > Global.max_turns:
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
		$Screen/Dice.text = "Game over!"
		
		$Screen/Dice.show()
		$Screen/Roll.hide()

func _ready():
	# Give each player a unique id
	var i = 1
	
	players = get_tree().get_nodes_in_group("players")
	for p in players:
		p.player_id = i
		i += 1
		if p.space == null and Global.new_game:
			p.space = get_node(start_node)
			p.translation = p.space.translation + PLAYER_TRANSLATION[i-2]
	
	Global.load_board_state()
	
	if player_turn <= players.size():
		camera_focus = players[player_turn - 1]
	
	if Global.award == Global.AWARD_T.winner_only:
		COOKIES_FOR_CAKE = 20
		$Screen/GetCake/Label.text = "Buy a cake for 20 cookies"
	
	# Initialize GUI
	if player_turn <= Global.amount_of_players:
		$Screen/Turn.text = "Turn: " + var2str(Global.turn)
		$Screen/Dice.text = "Roll " + players[player_turn - 1].player_name + "!"
	
	update_player_info()
	
	$Screen/Debug.setup()
	
	check_winner()
	
	# Show "your turn screen" for first player
	if current_minigame != null:
		show_minigame_info()
	else:
		_on_Roll_pressed()

# Function to check if the next player can roll or not
func _on_Roll_pressed():
	if wait_for_animation:
		return
	
	$Screen/GetCake.hide()
	
	if winner != null:
		return
	
	if splash_ended or player_turn > players.size():
		splash_ended = false
		roll()
		
		$Screen/Roll.hide()
	else:
		splash_ended = true
		var image = load(Global.character_loader.get_character_splash(Global.players[player_turn - 1].character)).get_data()
		image.resize(256, 256)
		
		$Screen/Splash/Background/Player.texture = ImageTexture.new()
		$Screen/Splash/Background/Player.texture.create_from_image(image)
		$Screen/Splash.play("show")
		
		if players[player_turn - 1].is_ai:
			get_tree().create_timer(1).connect("timeout", self, "_on_Roll_pressed")
		else:
			$Screen/Roll.show()
		
		$Screen/Dice.hide()

# Roll for the current plyaer
func roll():
	if winner != null:
		return
	
	if player_turn <= players.size():
		$Screen/Splash.play("hide")
		wait_for_animation = true
		end_turn = true
		
		var player = players[player_turn - 1]
		camera_focus = player
		
		var dice = (randi() % 6) + 1 # Random number between 1 & 6
		
		$Screen/Stepcounter.text = var2str(dice)
		step_count = dice
		
		do_step(player, dice)
		
		# Show which number was rolled
		$Screen/Dice.text = player.player_name + " rolled: " + var2str(dice) 
		$Screen/Dice.show()
	else:
		# All players have had their turn, goto mini-game
		var blue_team = []
		var red_team = []
		
		for p in players:
			match p.space.type:
				NODE.BLUE:
					blue_team.push_back(p.player_id)
				NODE.RED:
					red_team.push_back(p.player_id)
				_:
					if randi() % 2 == 0:
						blue_team.push_back(p.player_id)
					else:
						red_team.push_back(p.player_id)
		
		if blue_team.size() < red_team.size():
			var tmp = blue_team
			blue_team = red_team
			red_team = tmp
		
		Global.minigame_teams = [blue_team, red_team]
		
		match [blue_team.size(), red_team.size()]:
			[4, 0]:
				Global.minigame_type = Global.FREE_FOR_ALL
				current_minigame = Global.minigame_loader.get_random_ffa()
			[3, 1]:
				Global.minigame_type = Global.ONE_VS_THREE
				current_minigame = Global.minigame_loader.get_random_1v3()
			[2, 2]:
				Global.minigame_type = Global.TWO_VS_TWO
				current_minigame = Global.minigame_loader.get_random_2v2()
		
		yield(show_minigame_animation(), "completed")
		show_minigame_info()

# Moves a player num spaces forward and stops when a cake spot is encoutered
func do_step(player, num):
	if num <= 0:
		animation_ended(player.player_id)
	else:
		# Adds each animation step to the player_board.gd script
		# The last step is added during update_space(player.space)
		var previous_space = player.space
		for i in range(num - 1):
			# If there are multiple branches
			if player.space.next.size() > 1 and next_node == null:
				if player.is_ai == false:
					selected_id = 0
					
					for node in player.space.next:
						var arrow = preload("res://boards/node/arrow/arrow.tscn").instance()
						var dir = node.translation - player.space.translation
						
						dir = dir.normalized()
						
						arrow.id = selected_id
						arrow.next_node = node
						arrow.translation = player.space.translation
						arrow.rotation.y = atan2(dir.normalized().x, dir.normalized().z)
						
						selected_id += 1
						
						get_parent().add_child(arrow)
				
				selected_id = -1
				do_action = TURN_ACTION.CHOOSE_PATH
				
				end_turn = false
				
				# Player has not moved a space yet so only subtract with i
				steps_remaining = num - (i)
				
				if not previous_space == player.space:
					update_space(previous_space)
					update_space(player.space)
				else:
					update_space(player.space)
				
				return
			elif player.space.next.size() > 1 and not next_node == null:
				player.space = next_node
				next_node = null
			elif player.space.next.size() == 1:
				player.space = player.space.next[0]
			
			# If player passes a cake-spot
			if player.space.cake and player.cookies >= COOKIES_FOR_CAKE:
				do_action = TURN_ACTION.BUY_CAKE
				
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
		
		# Last step the player makes
		# ==============================
		# If there are multiple branches
		if player.space.next.size() > 1 and next_node == null:
			if player.is_ai == false:
				selected_id = 0
				
				for node in player.space.next:
					var arrow = preload("res://boards/node/arrow/arrow.tscn").instance()
					var dir = node.translation - player.space.translation
					
					dir = dir.normalized()
					
					arrow.id = selected_id
					arrow.next_node = node
					arrow.translation = player.space.translation
					arrow.rotation.y = atan2(dir.normalized().x, dir.normalized().z)
					
					selected_id += 1
					
					get_parent().add_child(arrow)
			
			do_action = TURN_ACTION.CHOOSE_PATH
			end_turn = false
			
			steps_remaining = 1
			selected_id = -1
			
			if not previous_space == player.space:
				update_space(previous_space)
				update_space(player.space)
			
			return
		elif player.space.next.size() > 1 and not next_node == null:
			player.space = next_node
			next_node = null
		elif player.space.next.size() == 1:
			player.space = player.space.next[0]
		
		if player.space.cake and player.cookies >= COOKIES_FOR_CAKE:
			
			do_action = TURN_ACTION.BUY_CAKE
			
			end_turn = false
			steps_remaining = 0
			
			update_space(previous_space)
			update_space(player.space)
			
			return
		
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
		NODE.YELLOW:
			end_turn = false
			do_action = CHOOSE_OPPONENT
			
			var rewards = Global.MINIGAME_DUEL_REWARDS.values()
			
			Global.minigame_type = Global.DUEL
			current_minigame = Global.minigame_loader.get_random_duel()
			Global.minigame_duel_reward = rewards[randi() % rewards.size()]

func update_space(space):
	var num  = 0
	var max_num = get_players_on_space(space)
	for player in players:
		if player.space == space:
			var offset = EMPTY_SPACE_PLAYER_TRANSLATION
			
			if max_num > 1:
				offset = PLAYER_TRANSLATION[num]
			
			player.destination.append(player.space.translation + offset)
			num += 1

func _unhandled_input(event):
	if player_turn <= players.size():
		if event.is_action_pressed("player" + var2str(player_turn) + "_ok") and not players[player_turn - 1].is_ai and end_turn == true:
			_on_Roll_pressed()
		elif end_turn == false and do_action == TURN_ACTION.CHOOSE_PATH and not players[player_turn - 1].is_ai:
			# Be able to choose path with controller or keyboard
			if event.is_action_pressed("player" + var2str(player_turn - 1) + "_left"):
				selected_id -= 1
				
				if selected_id < 0:
					selected_id = get_tree().get_nodes_in_group("arrows").size() - 1
			elif event.is_action_pressed("player" + var2str(player_turn - 1) + "_right"):
				selected_id += 1
				
				if selected_id >= get_tree().get_nodes_in_group("arrows").size():
					selected_id = 0
			elif event.is_action_pressed("player" + var2str(player_turn - 1) + "_ok") and selected_id >= 0:
				get_tree().get_nodes_in_group("arrows")[selected_id].pressed()
	
	if event.is_action_pressed("debug"):
		$Screen/Debug.popup()


func get_players_on_space(space):
	var num = 0
	for player in players:
		if(player.space == space):
			num += 1
	
	return num

func animation_ended(player_id):
	if player_id != player_turn :
		return
	
	var player = players[player_id - 1]
	
	if end_turn:
		player_turn += 1
		wait_for_animation = false
		_on_Roll_pressed()
	else:
		step_count += 1
		$Screen/Stepcounter.text = var2str(step_count)
		
		if not player.is_ai:
			wait_for_animation = true
			
			match do_action:
				TURN_ACTION.BUY_CAKE:
					$Screen/GetCake.show()
				TURN_ACTION.CHOOSE_OPPONENT:
					player_turn += 1
					yield(minigame_duel_reward_animation(), "completed")
					var players = get_tree().get_nodes_in_group("players")
					players.remove(players.find(player))
					
					var i = 1
					for p in players:
						var node = $Screen/DuelSelection.get_node("Player"+var2str(i))
						node.texture_normal = load(Global.character_loader.get_character_splash(Global.players[p.player_id - 1].character))
						node.connect("pressed", self, "_on_duel_opponent_select", [player.player_id, p.player_id])
						
						i += 1
					
					$Screen/DuelSelection.show()
		else:
			match do_action:
				TURN_ACTION.BUY_CAKE:
					var cakes = int(player.cookies / COOKIES_FOR_CAKE)
					player.cakes += cakes
					player.cookies -= COOKIES_FOR_CAKE * cakes
				TURN_ACTION.CHOOSE_PATH:
					next_node = player.space.next[randi() % player.space.next.size()]
				TURN_ACTION.CHOOSE_OPPONENT:
					player_turn += 1
					var players = get_tree().get_nodes_in_group("players")
					players.remove(players.find(player))
					
					Global.minigame_teams = [[players[randi() % players.size()].player_id], [player.player_id]]
					yield(minigame_duel_reward_animation(), "completed")
					yield(show_minigame_animation(), "completed")
					show_minigame_info()
					return
			
			get_tree().create_timer(1).connect("timeout", self, "_ai_continue_callback")

func animation_step(player_id):
	if player_id != player_turn:
		return
	
	step_count -= 1
	
	if step_count > 0:
		$Screen/Stepcounter.text = var2str(step_count)
	else:
		$Screen/Stepcounter.text = ""

func _ai_continue_callback():
	wait_for_animation = false
	end_turn = true
	
	do_step(players[player_turn - 1], steps_remaining)

func _process(delta):
	if camera_focus != null:
		var dir = camera_focus.translation - self.translation
		if(dir.length() > 0.01):
			self.translation += (CAMERA_SPEED * dir.length()) * dir.normalized() * delta
	
	# Automatically switch to next player when current player has finished moving
	if player_turn - 2 >= 0 and player_turn - 1 < Global.amount_of_players:
		var player = players[player_turn - 2]
		
		if camera_focus == player:
			if player.destination.size() == 0 and end_turn:
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

func hide_splash():
	$Screen/Splash/Background.hide()

func _on_GetCake_pressed():
	$Screen/BuyCake/HSlider.max_value = int(players[player_turn - 1].cookies / COOKIES_FOR_CAKE)
	
	if $Screen/BuyCake/HSlider.max_value == 1:
		$Screen/BuyCake/HSlider.hide()
	else:
		$Screen/BuyCake/HSlider.show()
	
	$Screen/GetCake.hide()
	$Screen/BuyCake.show()
	
	$Screen/BuyCake/HSlider.value = $Screen/BuyCake/HSlider.max_value
	$Screen/BuyCake/Amount.text = "x" + var2str(int($Screen/BuyCake/HSlider.max_value))

func _on_GetCake_abort():
	var player = players[player_turn - 1]
	
	$Screen/GetCake.hide()
	end_turn = true
	do_step(player, steps_remaining)

func _on_Buy_pressed():
	var amount = int($Screen/BuyCake/HSlider.value)
	
	var player = players[player_turn - 1]
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

func minigame_duel_reward_animation():
	var name
	for key in Global.MINIGAME_DUEL_REWARDS.keys():
		if Global.MINIGAME_DUEL_REWARDS[key] == Global.minigame_duel_reward:
			name = key
	
	if name == "TEN_COOKIES":
		$Screen/DuelReward/Value.text = "Winner steals 10 cookies"
	elif name == "ONE_CAKE":
		$Screen/DuelReward/Value.text = "Winner steals 1 cake"
	else:
		$Screen/DuelReward/Value.text = name
	
	$Screen/Dice.hide()
	
	$Screen/DuelReward.show()
	yield(get_tree().create_timer(2), "timeout")
	$Screen/DuelReward.hide()

func show_minigame_animation():
	var i = 1
	for team in Global.minigame_teams:
		for player_id in team:
			$Screen/MinigameTypeAnimation/Root.get_node("Player"+var2str(i)).texture = load(Global.character_loader.get_character_splash(Global.players[player_id - 1].character))
			i += 1
	
	match Global.minigame_type:
		Global.FREE_FOR_ALL:
			$Screen/MinigameTypeAnimation.play("FFA")
		Global.ONE_VS_THREE:
			$Screen/MinigameTypeAnimation.play("1v3")
		Global.TWO_VS_TWO:
			$Screen/MinigameTypeAnimation.play("2v2")
		Global.DUEL:
			$Screen/MinigameTypeAnimation.play("Duel")
	
	$Screen/Dice.hide()
	
	yield($Screen/MinigameTypeAnimation, "animation_finished")

func setup_character_viewport():
	var i = 1
	for team in Global.minigame_teams:
		for player_id in team:
			var player = $Screen/MinigameInformation/Characters/Viewport.get_node("Player" + var2str(i))
			var new_model = load(Global.character_loader.get_character_path(Global.players[player_id - 1].character)).instance()
			
			new_model.name = player.name
			new_model.translation = player.translation
			new_model.scale = player.scale
			new_model.rotation = player.rotation
			
			player.replace_by(new_model)
			
			if new_model.has_node("AnimationPlayer"):
				new_model.get_node("AnimationPlayer").play("idle")
				if i > 0:
					new_model.get_node("AnimationPlayer").playback_speed = 0
			
			i += 1
	
	while i <= Global.amount_of_players:
		var player = $Screen/MinigameInformation/Characters/Viewport.get_node("Player" + var2str(i))
		player.hide()
		
		i += 1

func minigame_has_player(i):
	for team in Global.minigame_teams:
		for player_id in team:
			if player_id == i:
				return true
	
	return false

func show_minigame_info():
	setup_character_viewport()
	
	$Screen/MinigameInformation/Title.text = current_minigame.name
	$Screen/MinigameInformation/Description/Text.bbcode_text = current_minigame.description.en
	if current_minigame.image_path != null:
		$Screen/MinigameInformation/Screenshot.texture = load(current_minigame.image_path)
	
	for i in range(1, Global.amount_of_players + 1):
		var label = $Screen/MinigameInformation/Controls.get_node("Player" + var2str(i))
		if not minigame_has_player(i) or players[i - 1].is_ai:
			# If the player is controlled by an AI, there is no point in showing controls
			label.queue_free()
			continue
		
		label.bbcode_text = ""
		for action in current_minigame.used_controls:
			label.append_bbcode(CONTROL_HELPER.get_button_name(InputMap.get_action_list("player"+var2str(i) + "_" + action)[0]) + " - " + current_minigame.used_controls[action].en + "\n")
	
	$Screen/MinigameInformation.show()

func _on_Try_pressed():
	Global.goto_minigame(current_minigame, true)

func _on_Play_pressed():
	if Global.minigame_type != Global.DUEL:
		Global.turn += 1
		player_turn = 1
	Global.goto_minigame(current_minigame)
	current_minigame = null

func _on_Controls_tab_changed(tab):
	var last_tab_selected =$Screen/MinigameInformation/Controls.get_previous_tab()
	var last_player = $Screen/MinigameInformation/Characters/Viewport.get_node("Player" + var2str(last_tab_selected+1))
	var player = $Screen/MinigameInformation/Characters/Viewport.get_node("Player" + var2str(tab+1))
	
	if last_player.has_node("AnimationPlayer"):
		# Pause the animation, when it is no longer selected
		last_player.get_node("AnimationPlayer").seek(0, true)
		last_player.get_node("AnimationPlayer").playback_speed = 0
	
	if player.has_node("AnimationPlayer"):
		player.get_node("AnimationPlayer").playback_speed = 1
	
	$Screen/MinigameInformation/Characters/Viewport/Indicator.translation = player.translation + Vector3(0, 1.5, 0)

func _on_duel_opponent_select(self_id, other_id):
	Global.minigame_teams = [[other_id], [self_id]]
	
	$Screen/DuelSelection.hide()
	yield(show_minigame_animation(), "completed")
	show_minigame_info()
