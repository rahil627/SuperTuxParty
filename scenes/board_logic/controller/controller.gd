extends Spatial

signal trigger_event(player, space)

# This signal is emitted with a
# 'call_deferred("emit_signal", "event_completed")'.
# warning-ignore:unused_signal
signal event_completed

signal cake_shopping_completed
signal shopping_completed

signal path_chosen

# If multiple players get on one space, this array decides the translation of
# each.
const PLAYER_TRANSLATION = [Vector3(0, 0.25, -0.75), Vector3(0.75, 0.25, 0),
		Vector3(0, 0.25, 0.75), Vector3(-0.75, 0.25, 0)]
const EMPTY_SPACE_PLAYER_TRANSLATION = Vector3(0, 0.25, 0)
const CAMERA_SPEED = 6

const PLAYER = preload("res://scenes/board_logic/player_board/player_board.gd")

export var COOKIES_FOR_CAKE := 30
export var MAX_TURNS := 10

var selected_item: Item

# Used internally for selecting a space with buttons.
var selected_space
var selected_space_distance: int
var select_space_max_distance: int

# Array containing the player nodes.
var players: Array

# Keeps track of whose turn it is.
var player_turn := 1
var winner

var camera_focus
var end_turn := true

# Next node for player to go to when the player has chosen a path.
var next_node

enum EDITOR_NODE_LINKING_DISPLAY {
	DISABLED,
	NEXT_NODES,
	PREV_NODES,
	ALL
}

enum TURN_ACTION {
	NONE,
	BUY_CAKE,
	CHOOSE_PATH,
	LAND_ON_SPACE,
	SHOP
}

# Path to the node, where Players start.
export var start_node: NodePath
export(EDITOR_NODE_LINKING_DISPLAY) var show_linking_type: int =\
		EDITOR_NODE_LINKING_DISPLAY.ALL

# Stores the amount of steps the current player still needs to take,
# to complete his roll.
# Used when the player movement is interrupted because of a cake spot.
var steps_remaining := 0

# Stores the value of steps that still need to be performed after a dice roll.
# Used for display.
var step_count := 0

# Stores which action the player will perform when stopping during their turn.
var do_action: int = TURN_ACTION.NONE

# Store if the splash for a character was already shown.
var splash_ended := false

# Flag that indicates if the input needs to wait for the animation to finish.
var wait_for_animation := false

var current_minigame

func check_winner() -> void:
	if Global.turn > MAX_TURNS:
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
						message = tr("CONTEXT_LABEL_OUTCOME_DRAW")

		if message != tr("CONTEXT_LABEL_OUTCOME_DRAW"):
			message = tr("CONTEXT_LABEL_OUTCOME_WINNER_IS_PLAYER") %\
					[winner.player_name]

		$Screen/Turn.text = message
		$Screen/Dice.text = tr("CONTEXT_LABEL_OUTCOME_GAME_OVER")

		$Screen/Dice.show()
		$Screen/Roll.hide()

func _ready() -> void:
	# Give each player a unique id.
	var i = 1

	players = get_tree().get_nodes_in_group("players")
	for p in players:
		p.player_id = i
		p.connect("walking_step", self, "animation_step", [p.player_id])
		p.connect("walking_ended", self, "animation_ended", [p.player_id])
		i += 1
		if p.space == null and Global.new_game:
			p.space = get_node(start_node)
			p.translation = p.space.translation + PLAYER_TRANSLATION[i-2]

	Global.load_board_state()

	if player_turn <= players.size():
		camera_focus = players[player_turn - 1]

	$Screen/GetCake/Label.text = tr("CONTEXT_LABEL_BUY_CAKE") % COOKIES_FOR_CAKE

	# Initialize GUI.
	if player_turn <= Global.amount_of_players:
		$Screen/Turn.text = tr("CONTEXT_LABEL_TURN_NUM") % [Global.turn]
		$Screen/Dice.text = tr("CONTEXT_LABEL_ROLL_PLAYER") %\
				[players[player_turn - 1].player_name]

	update_player_info()

	$Screen/Debug.setup()

	check_winner()

	# Show "your turn screen" for first player.
	if current_minigame != null:
		show_minigame_info()
	else:
		_on_Roll_pressed()

# Function to check if the next player can roll or not.
func _on_Roll_pressed() -> void:
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

		$Screen/Splash/Background/Player.texture =\
				load(Global.character_loader.get_character_splash(\
				Global.players[player_turn - 1].character))
		$Screen/Splash.play("show")

		if players[player_turn - 1].is_ai:
			get_tree().create_timer(1).connect("timeout", self, "_on_Roll_pressed")
		else:
			$Screen/Roll.show()

		camera_focus = players[player_turn - 1]

		$Screen/Dice.hide()

# Roll for the current player.
func roll(steps = null) -> void:
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
			$Screen/Dice.text = tr("CONTEXT_LABEL_PLAYER_ROLLED") %\
					[player.player_name, dice]
			$Screen/Dice.show()
			return

		match selected_item.type:
			Item.TYPES.DICE:
				var dice = selected_item.activate(player, self)

				$Screen/Stepcounter.text = var2str(dice)
				step_count = dice

				do_step(player, dice)

				# Show which number was rolled.
				$Screen/Dice.text = tr("CONTEXT_LABEL_PLAYER_ROLLED") %\
						[player.player_name, dice]
				$Screen/Dice.show()
			Item.TYPES.PLACABLE:
				yield(select_space(player, selected_item.max_place_distance),
						"completed")
				selected_space.trap = selected_item
				selected_space.trap_player = player

				camera_focus = selected_space
				yield(get_tree().create_timer(1), "timeout")
				camera_focus = player

				# Use default dice.
				var dice = (randi() % 6) + 1

				$Screen/Stepcounter.text = var2str(dice)
				step_count = dice

				do_step(player, dice)

				# Show which number was rolled
				$Screen/Dice.text = tr("CONTEXT_LABEL_PLAYER_ROLLED") %\
						[player.player_name, dice]
				$Screen/Dice.show()
			Item.TYPES.ACTION:
				selected_item.activate(player, self)

				# Use default dice.
				var dice = (randi() % 6) + 1

				$Screen/Stepcounter.text = var2str(dice)
				step_count = dice

				do_step(player, dice)

				# Show which number was rolled
				$Screen/Dice.text = tr("CONTEXT_LABEL_PLAYER_ROLLED") %\
						[player.player_name, dice]
				$Screen/Dice.show()
	else:
		# All players have had their turn, goto mini-game.
		var blue_team = []
		var red_team = []

		for p in players:
			match p.space.type:
				NodeBoard.NODE_TYPES.BLUE:
					blue_team.push_back(p.player_id)
				NodeBoard.NODE_TYPES.RED:
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

func create_choose_path_arrows(player, previous_space) -> void:
	if not player.is_ai:
		var first = null
		var previous = null
		for node in player.space.next:
			var arrow = preload("res://scenes/board_logic/node/arrow/" +\
					"arrow.tscn").instance()
			var dir = node.translation - player.space.translation

			dir = dir.normalized()

			if first != null:
				arrow.previous_arrow = previous
				previous.next_arrow = arrow
			else:
				first = arrow

			arrow.next_node = node
			arrow.translation = player.space.translation
			arrow.rotation.y = atan2(dir.normalized().x, dir.normalized().z)

			arrow.connect("arrow_activated", self,
					"_on_choose_path_arrow_activated", [arrow])

			get_parent().add_child(arrow)
			previous = arrow

		first.previous_arrow = previous
		previous.next_arrow = first
		first.selected = true

	do_action = TURN_ACTION.CHOOSE_PATH

	end_turn = false

	# Undo last step, to update it with a new location
	player.destination.pop_back()
	if not previous_space == player.space:
		update_space(previous_space)
		update_space(player.space)
	else:
		update_space(player.space)

# Moves a player num spaces forward and stops when a cake spot is encountered.
func do_step(player, num: int) -> void:
	if num <= 0:
		update_space(player.space)
		do_action = TURN_ACTION.LAND_ON_SPACE
	else:
		# Adds each animation step to the player_board.gd script.
		# The last step is added during update_space(player.space).
		var previous_space = player.space
		var i = 0
		while i < num - 1:
			# If there are multiple branches.
			if player.space.next.size() > 1 and next_node == null:
				create_choose_path_arrows(player, previous_space)
				steps_remaining = num - i
				return
			elif player.space.next.size() > 1 and not next_node == null:
				player.space = next_node
				next_node = null
			elif player.space.next.size() == 1:
				player.space = player.space.next[0]

			# If the space is a special space, we need to count it as visited
			if player.space.is_visible_space():
				i += 1
			# If player passes a cake-spot.
			if player.space.cake and player.cookies >= COOKIES_FOR_CAKE:
				do_action = TURN_ACTION.BUY_CAKE

				end_turn = false
				steps_remaining = num - i

				update_space(previous_space)
				update_space(player.space)

				return
			# If player passes a shop space
			elif player.space.type == NodeBoard.NODE_TYPES.SHOP:
				do_action = TURN_ACTION.SHOP

				end_turn = false
				steps_remaining = num - i

				update_space(previous_space)
				update_space(player.space)

				return
			else:
				var offset: Vector3 = _get_player_offset(player.space)

				var walking_state = PLAYER.WalkingState.new()
				walking_state.space = player.space
				walking_state.position = player.space.translation + offset
				player.destination.append(walking_state)

		while true:
			# Last step the player makes.
			# ===============================
			# If there are multiple branches.
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
				if player.space.is_visible_space():
					steps_remaining = 0
				else:
					steps_remaining = 1

				update_space(previous_space)
				update_space(player.space)

				return
			elif player.space.type == NodeBoard.NODE_TYPES.SHOP:
				do_action = TURN_ACTION.SHOP

				end_turn = false
				if player.space.is_visible_space():
					steps_remaining = 0
				else:
					steps_remaining = 1

				update_space(previous_space)
				update_space(player.space)

				return

			if player.space.is_visible_space():
				# Reposition figures.
				update_space(previous_space)
				update_space(player.space)

				do_action = TURN_ACTION.LAND_ON_SPACE
				return
			else:
				var players_on_space = get_players_on_space(player.space) - 1
				var offset = EMPTY_SPACE_PLAYER_TRANSLATION

				if players_on_space > 0:
					offset = PLAYER_TRANSLATION[players_on_space]

				var walking_state = PLAYER.WalkingState.new()
				walking_state.space = player.space
				walking_state.position = player.space.translation + offset
				player.destination.append(walking_state)


func update_space(space) -> void:
	var num := 0
	for player in players:
		if player.space == space:
			var offset = _get_player_offset(player.space, num)

			var walking_state = PLAYER.WalkingState.new()
			walking_state.space = player.space
			walking_state.position = player.space.translation + offset
			player.destination.append(walking_state)
			num += 1

func raise_event(name: String, pressed: bool) -> void:
	var event = InputEventAction.new()
	event.action = name
	event.pressed = pressed

	Input.parse_input_event(event)

func _unhandled_input(event: InputEvent) -> void:
	if player_turn <= players.size():
		if event.is_action_pressed("player%d_ok" % player_turn) and\
				not players[player_turn - 1].is_ai and\
				end_turn == true and wait_for_animation == false:
			_on_Roll_pressed()
		elif not players[player_turn - 1].is_ai:
			if event.is_action_pressed("player%d_ok" % player_turn):
				raise_event("ui_accept", true)
			elif event.is_action_released("player%d_ok" % player_turn):
				raise_event("ui_accept", false)
			elif event.is_action_pressed("player%d_up" % player_turn):
				raise_event("ui_up", true)
			elif event.is_action_released("player%d_up" % player_turn):
				raise_event("ui_up", false)
			elif event.is_action_pressed("player%d_left" % player_turn):
				raise_event("ui_left", true)
			elif event.is_action_released("player%d_left" % player_turn):
				raise_event("ui_left", false)
			elif event.is_action_pressed("player%d_down" % player_turn):
				raise_event("ui_down", true)
			elif event.is_action_released("player%d_down" % player_turn):
				raise_event("ui_down", false)
			elif event.is_action_pressed("player%d_right" % player_turn):
				raise_event("ui_right", true)
			elif event.is_action_released("player%d_right" % player_turn):
				raise_event("ui_right", false)

	if event.is_action_pressed("debug"):
		$Screen/Debug.popup()

func get_players_on_space(space) -> int:
	var num = 0
	for player in players:
		if(player.space == space):
			num += 1

	return num

func _get_player_offset(space: NodeBoard, num := -1) -> Vector3:
	var players_on_space = get_players_on_space(space)
	if num < 0:
		num = players_on_space - 1

	if players_on_space > 1:
		return PLAYER_TRANSLATION[num]
	else:
		return EMPTY_SPACE_PLAYER_TRANSLATION


func generate_shop_items(space, items: Array, icons: Array, cost: Array) ->\
		void:
	var buyable_item_information: Array =\
			Global.item_loader.get_buyable_items()

	var buyable_items := []

	for item in buyable_item_information:
		buyable_items.append(Global.item_loader.get_item_path(item))

	for file in space.custom_items:
		buyable_items.erase(file)
		items.append(file)
		var instance = load(file).new()
		icons.append(instance.icon)
		cost.append(instance.item_cost)

	if items.size() > NodeBoard.MAX_STORE_SIZE:
		items.resize(NodeBoard.MAX_STORE_SIZE)

	var i: int = items.size()
	while i < NodeBoard.MAX_STORE_SIZE and buyable_items.size() != 0:
		var index: int = randi() % buyable_items.size()
		var random_item = buyable_items[index]
		buyable_items.remove(index)
		items.append(random_item)
		var instance = load(random_item).new()
		icons.append(instance.icon)
		cost.append(instance.item_cost)

		i = i + 1

func ai_do_shopping(player) -> void:
	var items := []
	var icons := []
	var cost := []
	generate_shop_items(player.space, items, icons, cost)

	# Index into the item array.
	var item_to_buy := -1
	for i in items.size():
		# Always keep enough money ready to buy a cake.
		# Buy the most expensive item that satisfies this criteria.
		if player.cookies - cost[i] >= COOKIES_FOR_CAKE and\
				(item_to_buy == -1 or cost[item_to_buy] < cost[i]):
			item_to_buy = i

	if item_to_buy != null and player.give_item(load(items[item_to_buy]).new()):
		player.cookies -= cost[item_to_buy]

func open_shop(player) -> void:
	var items := []
	var icons := []
	var cost := []
	generate_shop_items(player.space, items, icons, cost)

	for i in NodeBoard.MAX_STORE_SIZE:
		var element = $Screen/Shop.get_node("Item%d" % (i + 1))
		var texture_button = element.get_node("Image")
		if texture_button.is_connected("pressed", self, "_on_shop_item"):
			texture_button.disconnect("pressed", self, "_on_shop_item")

		if i < items.size():
			texture_button.connect("pressed", self, "_on_shop_item",
					[player, items[i], cost[i]])
			texture_button.texture_normal = icons[i]
			if texture_button.is_connected("focus_entered", self,
					"_on_focus_entered"):
				texture_button.disconnect("focus_entered", self,
						"_on_focus_entered")
			if texture_button.is_connected("focus_exited", self,
					"_on_focus_exited"):
				texture_button.disconnect("focus_exited", self,
						"_on_focus_exited")
			if texture_button.is_connected("mouse_entered", self,
					"_on_mouse_entered"):
				texture_button.disconnect("mouse_entered", self,
						"_on_mouse_entered")
			if texture_button.is_connected("mouse_exited", self,
					"_on_mouse_exited"):
				texture_button.disconnect("mouse_exited", self,
						"_on_mouse_exited")
			if texture_button.is_connected("pressed", self, "_on_item_select"):
				texture_button.disconnect("pressed", self, "_on_item_select")

			texture_button.connect("focus_entered", self, "_on_focus_entered",
					[texture_button])
			texture_button.connect("focus_exited", self, "_on_focus_exited",
					[texture_button])
			texture_button.connect("mouse_entered", self, "_on_mouse_entered",
					[texture_button])
			texture_button.connect("mouse_exited", self, "_on_mouse_exited",
					[texture_button])

			texture_button.material.set_shader_param("enable_shader", false)

			element.get_node("Cost/Amount").text = var2str(cost[i])
			if player.cookies < cost[i]:
				element.get_node("Cost/Amount").add_color_override(
						"font_color", Color(1, 0, 0))
			else:
				element.get_node("Cost/Amount").add_color_override(
						"font_color", Color(1, 1, 1))
		else:
			texture_button.texture_normal = null
			element.get_node("Cost/Amount").text = ""

	$Screen/Shop/Item1/Image.grab_focus()
	$Screen/Shop.show()

# This method needs to be called, after an event triggered by landing on a
# green space is fully processed.
func continue() -> void:
	call_deferred("emit_signal", "event_completed")

# Gets the reference to the node, on which the cake currently can be
# collected
func get_cake_space() -> NodeBoard:
	return get_tree().get_nodes_in_group("cake_nodes")[Global.cookie_space]

func buy_cake(player: Spatial) -> void:
	if player.cookies >= COOKIES_FOR_CAKE:
		if not player.is_ai:
			$Screen/GetCake.show()
			yield(self, "cake_shopping_completed")
		else:
			var cakes := int(player.cookies / COOKIES_FOR_CAKE)
			player.cakes += cakes
			player.cookies -= COOKIES_FOR_CAKE * cakes
			yield(get_tree().create_timer(0), "timeout")
	else:
		yield(get_tree().create_timer(0), "timeout")

# If we end up on a green space at the end of turn, we execute the board event
# if the board event does a movement, we need to ignore it.
# That's the purpose of this variable.
var _ignore_animation_ended := false

func animation_ended(player_id: int) -> void:
	if player_id != player_turn or _ignore_animation_ended:
		return

	var player = players[player_id - 1]

	if end_turn:
		if do_action == TURN_ACTION.LAND_ON_SPACE:
			# Activate the item placed onto the node if any.
			if player.space.trap != null and player.space.trap.activate_trap(
					player, player.space.trap_player, self):
				player.space.trap = null

			# Lose cookies if you land on red space.
			match player.space.type:
				NodeBoard.NODE_TYPES.RED:
					player.cookies -= 3
					if player.cookies < 0:
						player.cookies = 0
				NodeBoard.NODE_TYPES.GREEN:
					# If the event we will trigger, does move a player,
					# we need to ignore it.
					_ignore_animation_ended = true
					if(len(self.get_signal_connection_list("trigger_event")) > 0):
						emit_signal("trigger_event", player, player.space)
						yield(self, "event_completed")
					else:
						yield(get_tree().create_timer(1), "timeout")
					_ignore_animation_ended = false
				NodeBoard.NODE_TYPES.BLUE:
					player.cookies += 3
				NodeBoard.NODE_TYPES.YELLOW:
					var rewards: Array = Global.MINIGAME_DUEL_REWARDS.values()

					Global.minigame_type = Global.MINIGAME_TYPES.DUEL
					current_minigame = Global.minigame_loader.get_random_duel()
					Global.minigame_duel_reward =\
							rewards[randi() % rewards.size()]

					if not player.is_ai:
						yield(minigame_duel_reward_animation(), "completed")
						var players: Array =\
								get_tree().get_nodes_in_group("players")
						players.remove(players.find(player))

						var i := 1
						for p in players:
							var node = $Screen/DuelSelection.get_node(
									"Player" + var2str(i))
							node.texture_normal = load(Global.\
									character_loader.get_character_splash(
									Global.players[p.player_id - 1].character))

							node.connect("focus_entered", self,
									"_on_focus_entered", [node])
							node.connect("focus_exited", self,
									"_on_focus_exited", [node])
							node.connect("mouse_entered", self,
									"_on_mouse_entered", [node])
							node.connect("mouse_exited", self,
									"_on_mouse_exited", [node])
							node.connect("pressed", self,
									"_on_duel_opponent_select",
									[player.player_id, p.player_id])
							i += 1

						$Screen/DuelSelection/Player1.grab_focus()
						$Screen/DuelSelection.show()
					else:
						player_turn += 1
						var players: Array =\
								get_tree().get_nodes_in_group("players")
						players.remove(players.find(player))

						Global.minigame_teams = [[players[randi() %\
								players.size()].player_id], [player.player_id]]
						yield(minigame_duel_reward_animation(), "completed")
						yield(show_minigame_animation(), "completed")
						show_minigame_info()

					return

		player_turn += 1
		wait_for_animation = false
		_on_Roll_pressed()
	else:
		if not player.is_ai:
			wait_for_animation = true

			match do_action:
				TURN_ACTION.BUY_CAKE:
					buy_cake(player)
					yield(self, "cake_shopping_completed")
				TURN_ACTION.CHOOSE_PATH:
					next_node = yield(self, "path_chosen")
				TURN_ACTION.SHOP:
					open_shop(player)
					yield(self, "shopping_completed")

			end_turn = true
			do_step(player, steps_remaining)
		else:
			match do_action:
				TURN_ACTION.BUY_CAKE:
					buy_cake(player)
				TURN_ACTION.CHOOSE_PATH:
					next_node = player.space.next[randi() %\
							player.space.next.size()]
				TURN_ACTION.SHOP:
					ai_do_shopping(player)

			yield(get_tree().create_timer(1), "timeout")
			wait_for_animation = false
			end_turn = true

			do_step(players[player_turn - 1], steps_remaining)

func animation_step(space: NodeBoard, player_id: int) -> void:
	if player_id != player_turn:
		return

	if space.is_visible_space():
		step_count -= 1

	if step_count > 0:
		$Screen/Stepcounter.text = var2str(step_count)
	else:
		$Screen/Stepcounter.text = ""

func _process(delta: float) -> void:
	if camera_focus != null:
		var dir: Vector3 = camera_focus.translation - translation
		if dir.length() > 0.01:
			translation +=\
					CAMERA_SPEED * dir.length() * dir.normalized() * delta

# Function that updates the player info shown in the GUI.
func update_player_info() -> void:
	var i := 1

	for p in players:
		var info = get_node("Screen/PlayerInfo" + str(i))
		info.get_node("Player").text = p.player_name

		if p.cookies_gui == p.cookies:
			info.get_node("Cookies/Amount").text = str(p.cookies)
		elif p.destination.size() > 0:
			info.get_node("Cookies/Amount").text = str(p.cookies_gui)
		elif p.cookies_gui > p.cookies:
			info.get_node("Cookies/Amount").text = "-" + str(
					p.cookies_gui - p.cookies) + "  " + str(p.cookies_gui)
		else:
			info.get_node("Cookies/Amount").text = "+" + str(
					p.cookies - p.cookies_gui) + "  " + str(p.cookies_gui)

		info.get_node("Cakes/Amount").text = str(p.cakes)
		for j in PLAYER.MAX_ITEMS:
			var item
			if j < p.items.size():
				item = p.items[j]
			var texture_rect = info.get_node("Items/" + str(j))
			if item != null:
				texture_rect.texture = item.icon
			else:
				texture_rect.texture = null

			j += 1

		i += 1

func hide_splash() -> void:
	$Screen/Splash/Background.hide()

func _on_GetCake_pressed() -> void:
	$Screen/BuyCake/HSlider.max_value =\
			int(players[player_turn - 1].cookies / COOKIES_FOR_CAKE)

	if $Screen/BuyCake/HSlider.max_value == 1:
		$Screen/BuyCake/HSlider.hide()
	else:
		$Screen/BuyCake/HSlider.show()

	$Screen/GetCake.hide()
	$Screen/BuyCake.show()

	$Screen/BuyCake/HSlider.value = $Screen/BuyCake/HSlider.max_value
	$Screen/BuyCake/Amount.text =\
			"x" + var2str(int($Screen/BuyCake/HSlider.max_value))

func _on_GetCake_abort() -> void:
	$Screen/GetCake.hide()

	emit_signal("cake_shopping_completed")

func _on_Buy_pressed() -> void:
	var amount := int($Screen/BuyCake/HSlider.value)

	var player = players[player_turn - 1]
	player.cookies -= COOKIES_FOR_CAKE * amount
	player.cakes += amount

	$Screen/BuyCake.hide()

	emit_signal("cake_shopping_completed")

func _on_Abort_pressed() -> void:
	$Screen/BuyCake.hide()
	$Screen/GetCake.show()

func _on_HSlider_value_changed(value: float) -> void:
	$Screen/BuyCake/Amount.text = "x" + str(int(value))

func minigame_duel_reward_animation() -> void:
	var name: String
	for key in Global.MINIGAME_DUEL_REWARDS.keys():
		if Global.MINIGAME_DUEL_REWARDS[key] == Global.minigame_duel_reward:
			name = key

	if name == "TEN_COOKIES":
		$Screen/DuelReward/Value.text = tr("CONTEXT_LABEL_STEAL_TEN_COOKIES")
	elif name == "ONE_CAKE":
		$Screen/DuelReward/Value.text = tr("CONTEXT_LABEL_STEAL_ONE_CAKE")
	else:
		$Screen/DuelReward/Value.text = name

	$Screen/Dice.hide()

	$Screen/DuelReward.show()
	yield(get_tree().create_timer(2), "timeout")
	$Screen/DuelReward.hide()

func show_minigame_animation() -> void:
	var i := 1
	for team in Global.minigame_teams:
		for player_id in team:
			$Screen/MinigameTypeAnimation/Root.get_node(
					"Player" + str(i)).texture = load(
					Global.character_loader.get_character_splash(
					Global.players[player_id - 1].character))
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

func setup_character_viewport() -> void:
	var i := 1
	for team in Global.minigame_teams:
		for player_id in team:
			var player =\
					$Screen/MinigameInformation/Characters/Viewport.get_node(
					"Player" + var2str(i))
			var new_model = load(Global.character_loader.get_character_path(
					Global.players[player_id - 1].character)).instance()

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
		var player =\
				$Screen/MinigameInformation/Characters/Viewport.get_node(
				"Player" + var2str(i))
		player.hide()

		i += 1

func minigame_has_player(id: int) -> bool:
	for team in Global.minigame_teams:
		for player_id in team:
			if player_id == id:
				return true

	return false

func _get_translation(dictionary: Dictionary) -> String:
	var locale: String = TranslationServer.get_locale()

	if dictionary.has(locale):
		return dictionary.get(locale)
	elif dictionary.has(locale.substr(0, 2)):
		# Check if, e.g. de is present if locale is de_DE.
		return dictionary.get(locale.substr(0, 2))
	elif dictionary.has("en"):
		return dictionary.en
	else:
		var values = dictionary.values()
		if values.size() > 0:
			return values[0]

		return "Unable to get translation"

func show_minigame_info() -> void:
	setup_character_viewport()

	$Screen/MinigameInformation/Buttons/Play.grab_focus()

	$Screen/MinigameInformation/Title.text = current_minigame.name
	$Screen/MinigameInformation/Description/Text.bbcode_text =\
			_get_translation(current_minigame.description)
	if current_minigame.image_path != null:
		$Screen/MinigameInformation/Screenshot.texture =\
				load(current_minigame.image_path)

	for i in range(1, players.size() + 1):
		var label = $Screen/MinigameInformation/Controls.get_node(
				"Player" + str(i))
		if not minigame_has_player(i) or players[i - 1].is_ai:
			# If the player is controlled by an AI, there is no point in
			# showing controls.
			label.queue_free()
			continue

		label.bbcode_text = ""
		for action in current_minigame.used_controls:
			label.append_bbcode(ControlHelper.get_button_name(
					InputMap.get_action_list("player" + str(i) + "_" +
					action)[0]) + " - " + _get_translation(
					current_minigame.used_controls[action]) + "\n")

	$Screen/MinigameInformation.show()

func _on_Try_pressed() -> void:
	Global.goto_minigame(current_minigame, true)

func _on_Play_pressed():
	if Global.minigame_type != Global.MINIGAME_TYPES.DUEL:
		Global.turn += 1
		player_turn = 1
	Global.goto_minigame(current_minigame)
	current_minigame = null

func _on_Controls_tab_changed(tab: int) -> void:
	var last_tab_selected: int =\
			$Screen/MinigameInformation/Controls.get_previous_tab()
	var last_player = $Screen/MinigameInformation/Characters/Viewport.get_node(
			"Player" + str(last_tab_selected + 1))
	var player = $Screen/MinigameInformation/Characters/Viewport.get_node(
			"Player" + str(tab + 1))

	if last_player.has_node("AnimationPlayer"):
		# Pause the animation, when it is no longer selected
		last_player.get_node("AnimationPlayer").seek(0, true)
		last_player.get_node("AnimationPlayer").playback_speed = 0

	if player.has_node("AnimationPlayer"):
		player.get_node("AnimationPlayer").playback_speed = 1

	$Screen/MinigameInformation/Characters/Viewport/Indicator.translation =\
			player.translation + Vector3(0, 1.5, 0)

func _on_choose_path_arrow_activated(arrow) -> void:
	emit_signal("path_chosen", arrow.next_node)

func _on_duel_opponent_select(self_id: int, other_id: int) -> void:
	player_turn += 1
	Global.minigame_teams = [[other_id], [self_id]]

	$Screen/DuelSelection.hide()
	yield(show_minigame_animation(), "completed")
	show_minigame_info()

func _on_focus_entered(button) -> void:
	button.material.set_shader_param("enable_shader", true)

func _on_focus_exited(button) -> void:
	button.material.set_shader_param("enable_shader", false)

func _on_mouse_entered(button) -> void:
	button.material.set_shader_param("enable_shader", true)

func _on_mouse_exited(button) -> void:
	if not button.has_focus():
		button.material.set_shader_param("enable_shader", false)

signal item_selected

func select_item(player) -> void:
	var i := 1
	for item in player.items:
		var node = $Screen/ItemSelection.get_node("Item" + str(i))
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

	# Clear all remaining item slots.
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
		var item_id: int = (randi() % player.items.size()) + 1
		$Screen/ItemSelection.get_node("Item" + var2str(item_id)).grab_focus()
		yield(get_tree().create_timer(0.25), "timeout")

		selected_item = player.items[item_id - 1]
		$Screen/ItemSelection.hide()
	else:

		$Screen/ItemSelection/Item1.grab_focus()

		yield(self, "item_selected")

func _on_item_select(player, item) -> void:
	selected_item = item

	# Remove the item from the inventory if it is consumed.
	if selected_item.is_consumed:
		player.remove_item(item)

	# Reset the state.
	$Screen/ItemSelection.hide()

	# Continue execution.
	emit_signal("item_selected")

signal space_selected

func get_next_spaces(space: NodeBoard):
	var result = []

	for p in space.next:
		if p.is_visible_space():
			result.append(p)
		else:
			result += get_next_spaces(p)

	return result

func get_prev_spaces(space: NodeBoard):
	var result = []

	for p in space.prev:
		if p.is_visible_space():
			result.append(p)
		else:
			result += get_prev_spaces(p)

	return result

func select_space(player, max_distance: int) -> void:
	if player.is_ai:
		# Select random space in front of or behind player
		var distance: int = (randi() % (2*max_distance + 1)) - max_distance
		selected_space = player.space

		if distance > 0:
			while distance > 0:
				var possible_spaces = get_next_spaces(selected_space)
				if possible_spaces.size() == 0:
					break

				selected_space = possible_spaces[randi() %\
						possible_spaces.size()]
				distance -= 1
		else:
			while distance < 0:
				var possible_spaces = get_prev_spaces(selected_space)
				if possible_spaces.size() == 0:
					break

				selected_space = possible_spaces[randi() %\
						possible_spaces.size()]
				distance += 1

		yield(get_tree().create_timer(1), "timeout")
	else:
		selected_space_distance = 0
		select_space_max_distance = max_distance

		selected_space = player.space
		show_select_space_arrows()

		yield(self, "space_selected")

func show_select_space_arrows() -> void:
	var keep_arrow = preload(\
			"res://scenes/board_logic/node/arrow/arrow_keep.tscn").instance()

	keep_arrow.next_node = selected_space
	keep_arrow.translation = selected_space.translation

	keep_arrow.connect("arrow_activated", self,
			"_on_select_space_arrow_activated", [keep_arrow, 0])

	get_parent().add_child(keep_arrow)

	var previous = keep_arrow

	if selected_space_distance < select_space_max_distance:
		for node in get_next_spaces(selected_space):
			var arrow = preload("res://scenes/board_logic/node/arrow/" +\
					"arrow.tscn").instance()
			var dir: Vector3 = node.translation - selected_space.translation

			dir = dir.normalized()

			arrow.previous_arrow = previous
			previous.next_arrow = arrow

			arrow.next_node = node
			arrow.translation = selected_space.translation
			arrow.rotation.y = atan2(dir.normalized().x, dir.normalized().z)

			arrow.connect("arrow_activated", self,
					"_on_select_space_arrow_activated", [arrow, 1])

			get_parent().add_child(arrow)
			previous = arrow

	if selected_space_distance > -select_space_max_distance:
		for node in get_prev_spaces(selected_space):
			var arrow = preload("res://scenes/board_logic/node/arrow/" +\
					"arrow.tscn").instance()
			var dir: Vector3 = node.translation - selected_space.translation

			dir = dir.normalized()

			arrow.previous_arrow = previous
			previous.next_arrow = arrow

			arrow.next_node = node
			arrow.translation = selected_space.translation
			arrow.rotation.y = atan2(dir.normalized().x, dir.normalized().z)

			arrow.connect("arrow_activated", self,
					"_on_select_space_arrow_activated", [arrow, -1])

			get_parent().add_child(arrow)
			previous = arrow

	previous.next_arrow = keep_arrow
	keep_arrow.previous_arrow = previous

	keep_arrow.selected = true

	camera_focus = selected_space

func _on_select_space_arrow_activated(arrow, distance: int) -> void:
	if arrow.next_node == selected_space:
		camera_focus = players[player_turn - 1]

		emit_signal("space_selected")
		return

	selected_space = arrow.next_node
	selected_space_distance += distance

	show_select_space_arrows()

func _on_shop_item(player, item, cost: int) -> void:
	if player.cookies >= cost and player.give_item(load(item).new()):
		player.cookies -= cost
	elif player.cookies < cost:
		$Screen/Shop/Notification.dialog_text =\
				tr("CONTEXT_NOTIFICATION_NOT_ENOUGH_COOKIES")
		# Make it visible or else Godot does not recalculate the size
		# Temporary until fixed in Godot.
		$Screen/Shop/Notification.show()

		$Screen/Shop/Notification.popup_centered()
	else:
		$Screen/Shop/Notification.dialog_text =\
				tr("CONTEXT_NOTIFICATION_NOT_ENOUGH_SPACE")
		# Make it visible or else Godot does not recalculate the size
		# Temporary until fixed in Godot.
		$Screen/Shop/Notification.show()

		$Screen/Shop/Notification.popup_centered()

func _on_Shop_Back_pressed() -> void:
	$Screen/Shop.hide()

	emit_signal("shopping_completed")
