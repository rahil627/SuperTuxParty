extends Spatial

# If multiple players get on one space, this array decides the translation of each
const PLAYER_TRANSLATION = [Vector3(0, 0.25, -0.75), Vector3(0.75, 0.25, 0), Vector3(0, 0.25, 0.75), Vector3(-0.75, 0.25, 0)]
const EMPTY_SPACE_PLAYER_TRANSLATION = Vector3(0, 0.25, 0)
const CAMERA_SPEED = 6

const CONTROL_HELPER = preload("res://scripts/control_helper.gd")
const NODE = preload("res://scenes/board_logic/node/node.gd")
const ITEM = preload("res://plugins/items/item.gd")

var COOKIES_FOR_CAKE = 30

# Used internally for selecting a path on the board with buttons
var enable_select_arrows = false
var selected_id = -1

# Used internally for selecting a duel opponent with buttons
var selected_opponent = -1

# Used internally for selecting an item with buttons
var selected_item_id = -1
var selected_item = null

# Used internally for selecting a space with buttons
var selected_space_arrow_id = -1
var selected_space
var selected_space_distance
var select_space_max_distance

# Array containing the player nodes
var players = null 

# Keeps track of whose turn it is
var player_turn = 1 
var winner = null

var camera_focus = null
var end_turn = true

# Next node for player to go to when the player has chosen a path
var next_node = null

enum EDITOR_NODE_LINKING_DISPLAY {
	DISABLED,
	NEXT_NODES,
	PREV_NODES,
	ALL
}

enum TURN_ACTION {
	BUY_CAKE,
	CHOOSE_PATH,
	LAND_ON_SPACE,
	SHOP
}

# Path to the node, where Players start
export(NodePath) var start_node
export(EDITOR_NODE_LINKING_DISPLAY) var show_linking_type = EDITOR_NODE_LINKING_DISPLAY.ALL

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
	
	if Global.award == Global.AWARD_TYPE.WINNER_ONLY:
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
		
		$Screen/Splash/Background/Player.texture = load(Global.character_loader.get_character_splash(Global.players[player_turn - 1].character))
		$Screen/Splash.play("show")
		
		if players[player_turn - 1].is_ai:
			get_tree().create_timer(1).connect("timeout", self, "_on_Roll_pressed")
		else:
			$Screen/Roll.show()
		
		camera_focus = players[player_turn - 1]
		
		$Screen/Dice.hide()

# Roll for the current player
func roll(steps = null):
	if winner != null:
		return
	
	if player_turn <= players.size():
		$Screen/Splash.play("hide")
		wait_for_animation = true
		end_turn = true
		
		var player = players[player_turn - 1]
		camera_focus = player
		
		if steps == null:
			yield(select_item(player), "completed")
		else:
			var dice = steps
			
			$Screen/Stepcounter.text = var2str(dice)
			step_count = dice
			
			do_step(player, dice)
			
			# Show which number was rolled
			$Screen/Dice.text = player.player_name + " rolled: " + var2str(dice)
			$Screen/Dice.show()
			return
		
		match selected_item.type:
			ITEM.TYPES.DICE:
				var dice = selected_item.activate(player, self)
				
				$Screen/Stepcounter.text = var2str(dice)
				step_count = dice
				
				do_step(player, dice)
				
				# Show which number was rolled
				$Screen/Dice.text = player.player_name + " rolled: " + var2str(dice) 
				$Screen/Dice.show()
			ITEM.TYPES.PLACABLE:
				yield(select_space(player, selected_item.max_place_distance), "completed")
				selected_space.trap = selected_item
				selected_space.trap_player = player
				
				camera_focus = selected_space
				yield(get_tree().create_timer(1), "timeout")
				camera_focus = player
				
				# Use default dice
				var dice = (randi() % 6) + 1
				
				$Screen/Stepcounter.text = var2str(dice)
				step_count = dice
				
				do_step(player, dice)
				
				# Show which number was rolled
				$Screen/Dice.text = player.player_name + " rolled: " + var2str(dice) 
				$Screen/Dice.show()
			ITEM.TYPES.ACTION:
				selected_item.activate(player, self)
				
				# Use default dice
				var dice = (randi() % 6) + 1
				
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
				NODE.NODE_TYPES.BLUE:
					blue_team.push_back(p.player_id)
				NODE.NODE_TYPES.RED:
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
				Global.minigame_type = Global.MINIGAME_TYPES.FREE_FOR_ALL
				current_minigame = Global.minigame_loader.get_random_ffa()
			[3, 1]:
				Global.minigame_type = Global.MINIGAME_TYPES.ONE_VS_THREE
				current_minigame = Global.minigame_loader.get_random_1v3()
			[2, 2]:
				Global.minigame_type = Global.MINIGAME_TYPES.TWO_VS_TWO
				current_minigame = Global.minigame_loader.get_random_2v2()
		
		yield(show_minigame_animation(), "completed")
		show_minigame_info()

func create_choose_path_arrows(player, previous_space):
	if not player.is_ai:
		enable_select_arrows = true
		selected_id = 0
		
		for node in player.space.next:
			var arrow = preload("res://scenes/board_logic/node/arrow/arrow.tscn").instance()
			var dir = node.translation - player.space.translation
			
			dir = dir.normalized()
			
			arrow.id = selected_id
			arrow.next_node = node
			arrow.translation = player.space.translation
			arrow.rotation.y = atan2(dir.normalized().x, dir.normalized().z)
			
			arrow.connect("arrow_activated", self, "_on_choose_path_arrow_activated", [arrow])
			
			selected_id += 1
			
			get_parent().add_child(arrow)
	
	selected_id = -1
	do_action = TURN_ACTION.CHOOSE_PATH
	
	end_turn = false
	
	if not previous_space == player.space:
		update_space(previous_space)
		update_space(player.space)
	else:
		update_space(player.space)

# Moves a player num spaces forward and stops when a cake spot is encountered
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
				create_choose_path_arrows(player, previous_space)
				# Player has not moved a space yet so only subtract with i
				steps_remaining = num - (i)
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
			# If player passes a shop space
			elif player.space.type == NODE.NODE_TYPES.SHOP:
				do_action = TURN_ACTION.SHOP
				
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
			create_choose_path_arrows(player, previous_space)
			steps_remaining = 1
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
		
		do_action = TURN_ACTION.LAND_ON_SPACE

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

func select_arrows_input(event):
	var arrows = get_tree().get_nodes_in_group("arrows")
	# Be able to choose path with controller or keyboard
	if event.is_action_pressed("player%d_left" % player_turn):
		selected_id -= 1
		
		if selected_id < 0:
			selected_id = arrows.size() - 1
	elif event.is_action_pressed("player%d_right" % player_turn):
		selected_id += 1
		
		if selected_id >= arrows.size():
			selected_id = 0
	elif event.is_action_pressed("player%d_ok" % player_turn) and selected_id >= 0:
		arrows[selected_id].pressed()

func select_opponent_input(event):
	# Be able to choose path with controller or keyboard
	if event.is_action_pressed("player%d_left" % (player_turn - 1)):
		selected_opponent -= 1
		
		if selected_opponent < 1:
			selected_opponent = 3
		
		$Screen/DuelSelection.get_node("Player%d" % selected_opponent).grab_focus()
	elif event.is_action_pressed("player%d_right" % (player_turn - 1)):
		selected_opponent += 1
		
		if selected_opponent > 3:
			selected_opponent = 1
		
		$Screen/DuelSelection.get_node("Player%d" % selected_opponent).grab_focus()
	elif event.is_action_pressed("player%d_ok" % (player_turn - 1)) and selected_opponent >= 0:
		$Screen/DuelSelection.get_node("Player%d" % selected_opponent).emit_signal("pressed")

func select_item_input(event):
	# Be able to choose items with controller or keyboard
	if event.is_action_pressed("player%d_left" % player_turn):
		selected_item_id -= 1
		
		if selected_item_id < 1:
			selected_item_id = players[player_turn - 1].items.size()
		
		$Screen/ItemSelection.get_node("Item%d" % selected_item_id).grab_focus()
	elif event.is_action_pressed("player%d_right" % player_turn):
		selected_item_id += 1
		
		if selected_item_id > players[player_turn - 1].items.size():
			selected_item_id = 1
		
		$Screen/ItemSelection.get_node("Item%d" % selected_item_id).grab_focus()
	elif event.is_action_pressed("player%d_ok" % player_turn) and selected_item_id >= 0:
		$Screen/ItemSelection.get_node("Item%d" % selected_item_id).emit_signal("pressed")

func _unhandled_input(event):
	if player_turn <= players.size():
		if event.is_action_pressed("player%d_ok" % player_turn) and not players[player_turn - 1].is_ai and end_turn == true and wait_for_animation == false:
			_on_Roll_pressed()
		elif enable_select_arrows and not players[player_turn - 1].is_ai:
			select_arrows_input(event)
		elif selected_opponent != -1 and not players[player_turn - 2].is_ai:
			select_opponent_input(event)
		elif selected_item_id != -1 and not players[player_turn - 1].is_ai:
			select_item_input(event)
	
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
		if do_action == TURN_ACTION.LAND_ON_SPACE:
			# Activate the item placed onto the node if any
			if player.space.trap != null and player.space.trap.activate(player, player.space.trap_player, self):
				player.space.trap = null
			
			# Lose cookies if you land on red space
			match player.space.type:
				NODE.NODE_TYPES.RED:
					player.cookies -= 3
					if player.cookies < 0:
						player.cookies = 0
				NODE.NODE_TYPES.GREEN:
					if get_parent().has_method("fire_event"):
						get_parent().fire_event(player, player.space)
						do_action = null
						return
				NODE.NODE_TYPES.BLUE:
					player.cookies += 3
				NODE.NODE_TYPES.YELLOW:
					var rewards = Global.MINIGAME_DUEL_REWARDS.values()
					
					Global.minigame_type = Global.MINIGAME_TYPES.DUEL
					current_minigame = Global.minigame_loader.get_random_duel()
					Global.minigame_duel_reward = rewards[randi() % rewards.size()]
					
					if not player.is_ai:
						player_turn += 1
						yield(minigame_duel_reward_animation(), "completed")
						var players = get_tree().get_nodes_in_group("players")
						players.remove(players.find(player))
						
						var i = 1
						for p in players:
							var node = $Screen/DuelSelection.get_node("Player"+var2str(i))
							node.texture_normal = load(Global.character_loader.get_character_splash(Global.players[p.player_id - 1].character))
							
							
							node.connect("focus_entered", self, "_on_focus_entered", [node])
							node.connect("focus_exited", self, "_on_focus_exited", [node])
							node.connect("mouse_entered", self, "_on_mouse_entered", [node])
							node.connect("mouse_exited", self, "_on_mouse_exited", [node])
							node.connect("pressed", self, "_on_duel_opponent_select", [player.player_id, p.player_id])
							i += 1
						
						$Screen/DuelSelection/Player1.grab_focus()
						selected_opponent = 1;
						$Screen/DuelSelection.show()
					else:
						player_turn += 1
						var players = get_tree().get_nodes_in_group("players")
						players.remove(players.find(player))
						
						Global.minigame_teams = [[players[randi() % players.size()].player_id], [player.player_id]]
						yield(minigame_duel_reward_animation(), "completed")
						yield(show_minigame_animation(), "completed")
						show_minigame_info()
					
					return
		
		player_turn += 1
		wait_for_animation = false
		_on_Roll_pressed()
	else:
		if do_action == TURN_ACTION.CHOOSE_PATH:
			step_count += 1
			$Screen/Stepcounter.text = var2str(step_count)
		
		if not player.is_ai:
			wait_for_animation = true
			
			match do_action:
				TURN_ACTION.BUY_CAKE:
					$Screen/GetCake.show()
				TURN_ACTION.SHOP:
					var buyable_item_information = Global.item_loader.get_buyable_items()
					
					var buyable_items = []
					var items = []
					var icons = []
					var cost = []
					
					for item in buyable_item_information:
						buyable_items.append(Global.item_loader.get_item_path(item))
					
					for file in player.space.custom_items:
						buyable_items.erase(file)
						items.append(file)
						var instance = load(file).new()
						icons.append(instance.icon)
						cost.append(instance.item_cost)
					
					if items.size() > NODE.MAX_STORE_SIZE:
						items.resize(NODE.MAX_STORE_SIZE)
					
					var i = items.size()
					while i < NODE.MAX_STORE_SIZE and buyable_items.size() != 0:
						var index = randi() % buyable_items.size()
						var random_item = buyable_items[index]
						buyable_items.remove(index)
						items.append(random_item)
						var instance = load(random_item).new()
						icons.append(instance.icon)
						cost.append(instance.item_cost)
						
						i = i + 1
					
					i = 0
					while i < NODE.MAX_STORE_SIZE:
						var element = $Screen/Shop.get_node("Item%d" % (i+1))
						var texture_button = element.get_node("Image")
						texture_button.disconnect("pressed", self, "_on_shop_item")
						
						
						if i < items.size():
							texture_button.connect("pressed", self, "_on_shop_item", [player, items[i], cost[i]])
							texture_button.texture_normal = icons[i]
							if texture_button.is_connected("focus_entered", self, "_on_focus_entered"):
								texture_button.disconnect("focus_entered", self, "_on_focus_entered")
							if texture_button.is_connected("focus_exited", self, "_on_focus_exited"):
								texture_button.disconnect("focus_exited", self, "_on_focus_exited")
							if texture_button.is_connected("mouse_entered", self, "_on_mouse_entered"):
								texture_button.disconnect("mouse_entered", self, "_on_mouse_entered")
							if texture_button.is_connected("mouse_exited", self, "_on_mouse_exited"):
								texture_button.disconnect("mouse_exited", self, "_on_mouse_exited")
							if texture_button.is_connected("pressed", self, "_on_item_select"):
								texture_button.disconnect("pressed", self, "_on_item_select")
							
							texture_button.connect("focus_entered", self, "_on_focus_entered", [texture_button])
							texture_button.connect("focus_exited", self, "_on_focus_exited", [texture_button])
							texture_button.connect("mouse_entered", self, "_on_mouse_entered", [texture_button])
							texture_button.connect("mouse_exited", self, "_on_mouse_exited", [texture_button])
							
							texture_button.material.set_shader_param("enable_shader", false)

							element.get_node("Cost/Amount").text = var2str(cost[i])
							if player.cookies < cost[i]:
								element.get_node("Cost/Amount").add_color_override("font_color", Color(1, 0, 0))
							else:
								element.get_node("Cost/Amount").add_color_override("font_color", Color(1, 1, 1))
						else:
							texture_button.texture_normal = null
							element.get_node("Cost/Amount").text = ""
						
						i = i + 1
					
					$Screen/Shop/Item1/Image.grab_focus()
					$Screen/Shop.show()
		else:
			match do_action:
				TURN_ACTION.BUY_CAKE:
					var cakes = int(player.cookies / COOKIES_FOR_CAKE)
					player.cakes += cakes
					player.cookies -= COOKIES_FOR_CAKE * cakes
				TURN_ACTION.CHOOSE_PATH:
					next_node = player.space.next[randi() % player.space.next.size()]
				TURN_ACTION.SHOP:
					# TODO
					pass
			
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
		Global.MINIGAME_TYPES.FREE_FOR_ALL:
			$Screen/MinigameTypeAnimation.play("FFA")
		Global.MINIGAME_TYPES.ONE_VS_THREE:
			$Screen/MinigameTypeAnimation.play("1v3")
		Global.MINIGAME_TYPES.TWO_VS_TWO:
			$Screen/MinigameTypeAnimation.play("2v2")
		Global.MINIGAME_TYPES.DUEL:
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
	
	for i in range(1, players.size() + 1):
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
	if Global.minigame_type != Global.MINIGAME_TYPES.DUEL:
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

func _on_choose_path_arrow_activated(arrow):
	var player = players[player_turn - 1]
	enable_select_arrows = false
	selected_id = -1
	
	next_node = arrow.next_node;
	end_turn = true
	do_step(player, steps_remaining)

func _on_duel_opponent_select(self_id, other_id):
	Global.minigame_teams = [[other_id], [self_id]]
	
	$Screen/DuelSelection.hide()
	yield(show_minigame_animation(), "completed")
	show_minigame_info()

func _on_focus_entered(button):
	button.material.set_shader_param("enable_shader", true)

func _on_focus_exited(button):
	button.material.set_shader_param("enable_shader", false)

func _on_mouse_entered(button):
	button.material.set_shader_param("enable_shader", true)

func _on_mouse_exited(button):
	if not button.has_focus():
		button.material.set_shader_param("enable_shader", false)

signal item_selected

func select_item(player):
	var i = 1
	for item in player.items:
		var node = $Screen/ItemSelection.get_node("Item"+var2str(i))
		node.texture_normal = item.icon
		
		if node.is_connected("focus_entered", self, "_on_focus_entered"):
			node.disconnect("focus_entered", self, "_on_focus_entered")
		if node.is_connected("focus_exited", self, "_on_focus_exited"):
			node.disconnect("focus_exited", self, "_on_focus_exited")
		if node.is_connected("mouse_entered", self, "_on_mouse_entered"):
			node.disconnect("mouse_entered", self, "_on_mouse_entered")
		if node.is_connected("mouse_exited", self, "_on_mouse_exited"):
			node.disconnect("mouse_exited", self, "_on_mouse_exited")
		if node.is_connected("pressed", self, "_on_item_select"):
			node.disconnect("pressed", self, "_on_item_select")
		
		node.connect("focus_entered", self, "_on_focus_entered", [node])
		node.connect("focus_exited", self, "_on_focus_exited", [node])
		node.connect("mouse_entered", self, "_on_mouse_entered", [node])
		node.connect("mouse_exited", self, "_on_mouse_exited", [node])
		node.connect("pressed", self, "_on_item_select", [player, item])
		
		node.material.set_shader_param("enable_shader", false)
		
		i += 1
	
	# Clear all remaining item slots
	while i <= player.MAX_ITEMS:
		var node = $Screen/ItemSelection.get_node("Item"+var2str(i))
		node.texture_normal = null
		
		if node.is_connected("focus_entered", self, "_on_focus_entered"):
			node.disconnect("focus_entered", self, "_on_focus_entered")
		if node.is_connected("focus_exited", self, "_on_focus_exited"):
			node.disconnect("focus_exited", self, "_on_focus_exited")
		if node.is_connected("mouse_entered", self, "_on_mouse_entered"):
			node.disconnect("mouse_entered", self, "_on_mouse_entered")
		if node.is_connected("mouse_exited", self, "_on_mouse_exited"):
			node.disconnect("mouse_exited", self, "_on_mouse_exited")
		if node.is_connected("pressed", self, "_on_item_select"):
			node.disconnect("pressed", self, "_on_item_select")
		
		node.material.set_shader_param("enable_shader", false)
		
		i += 1
	
	$Screen/ItemSelection.show()
	
	if player.is_ai:
		yield(get_tree().create_timer(0.75), "timeout")
		var item_id = (randi() % player.items.size()) + 1
		$Screen/ItemSelection.get_node("Item" + var2str(item_id)).grab_focus()
		yield(get_tree().create_timer(0.25), "timeout")
		
		selected_item = player.items[item_id - 1]
		$Screen/ItemSelection.hide()
	else:
		
		$Screen/ItemSelection/Item1.grab_focus()
		selected_item_id = 1
		
		yield(self, "item_selected")

func _on_item_select(player, item):
	selected_item = item
	
	# Remove the item from the inventory if it is consumed
	if selected_item.is_consumed:
		player.items.remove(player.items.find(item))
	
	# Reset the state
	selected_item_id = -1
	$Screen/ItemSelection.hide()
	
	# Continue execution
	emit_signal("item_selected")

signal space_selected

func select_space(player, max_distance):
	if player.is_ai:
		# Select random space in front of or behind player
		var distance = (randi() % (2*max_distance + 1)) - max_distance
		selected_space = player.space
		
		if distance > 0:
			while distance > 0:
				selected_space = selected_space.next[randi() % selected_space.next.size()]
				distance -= 1
		else:
			while distance < 0:
				selected_space = selected_space.prev[randi() % selected_space.prev.size()]
				
				distance += 1
		
		yield(get_tree().create_timer(1), "timeout")
	else:
		enable_select_arrows = true
		selected_id = 0
		selected_space_distance = 0
		select_space_max_distance = max_distance
		
		selected_space = player.space
		show_select_space_arrows()
		
		yield(self, "space_selected")

func show_select_space_arrows():
	var keep_arrow = preload("res://scenes/board_logic/node/arrow/arrow_keep.tscn").instance()
	var id = 0
	
	keep_arrow.id = id
	keep_arrow.next_node = selected_space
	keep_arrow.translation = selected_space.translation
	
	id += 1
	
	keep_arrow.connect("arrow_activated", self, "_on_select_space_arrow_activated", [keep_arrow, 0])
	
	get_parent().add_child(keep_arrow)
	
	if selected_space_distance < select_space_max_distance:
		for node in selected_space.next:
			var arrow = preload("res://scenes/board_logic/node/arrow/arrow.tscn").instance()
			var dir = node.translation - selected_space.translation
			
			dir = dir.normalized()
			
			arrow.id = id
			arrow.next_node = node
			arrow.translation = selected_space.translation
			arrow.rotation.y = atan2(dir.normalized().x, dir.normalized().z)
			
			id += 1
			
			arrow.connect("arrow_activated", self, "_on_select_space_arrow_activated", [arrow, +1])
			
			get_parent().add_child(arrow)
	
	if selected_space_distance > -select_space_max_distance:
		for node in selected_space.prev:
			var arrow = preload("res://scenes/board_logic/node/arrow/arrow.tscn").instance()
			var dir = node.translation - selected_space.translation
			
			dir = dir.normalized()
			
			arrow.id = id
			arrow.next_node = node
			arrow.translation = selected_space.translation
			arrow.rotation.y = atan2(dir.normalized().x, dir.normalized().z)
			
			id += 1
			
			arrow.connect("arrow_activated", self, "_on_select_space_arrow_activated", [arrow, -1])
			
			get_parent().add_child(arrow)
	
	camera_focus = selected_space

func _on_select_space_arrow_activated(arrow, distance):
	selected_id = -1
	
	if arrow.next_node == selected_space:
		enable_select_arrows = false
		camera_focus = players[player_turn - 1]
		
		emit_signal("space_selected")
		return
	
	selected_space = arrow.next_node
	selected_space_distance += distance
	
	show_select_space_arrows()

func _on_shop_item(player, item, cost):
	if player.cookies >= cost and player.give_item(load(item).new()):
		player.cookies -= cost
	elif player.cookies < cost:
		$Screen/Shop/Notification.dialog_text = "You don't have enough cookies to buy that"
		# Make it visible or else Godot does not recalculate the size
		# Temporary until fixed in Godot
		$Screen/Shop/Notification.show()
		
		$Screen/Shop/Notification.popup_centered()
	else:
		$Screen/Shop/Notification.dialog_text = "You don't have space left in your inventory"
		# Make it visible or else Godot does not recalculate the size
		# Temporary until fixed in Godot
		$Screen/Shop/Notification.show()
		
		$Screen/Shop/Notification.popup_centered()

func _on_Shop_Back_pressed():
	$Screen/Shop.hide()
	
	end_turn = true
	do_step(players[player_turn-1], steps_remaining)
