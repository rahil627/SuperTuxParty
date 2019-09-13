extends Spatial

signal trigger_event(player, space)


signal path_chosen

signal next_player
signal rolled(player, num)

signal _calculate_step
# This signal is emitted with a
# 'call_deferred("emit_signal", "_step_finished")'.
# warning-ignore:unused_signal
signal _step_finished(is_visible)
# This signal is emitted with a
# 'call_deferred("emit_signal", "_event_completed")'.
# warning-ignore:unused_signal
signal _event_completed

# If multiple players get on one space, this array decides the translation of
# each.
const PLAYER_TRANSLATION = [Vector3(0, 0.25, -0.75), Vector3(0.75, 0.25, 0),
		Vector3(0, 0.25, 0.75), Vector3(-0.75, 0.25, 0)]
const EMPTY_SPACE_PLAYER_TRANSLATION = Vector3(0, 0.25, 0)
const CAMERA_SPEED = 6

const PLAYER = preload("res://scenes/board_logic/player_board/player_board.gd")

export var COOKIES_FOR_CAKE := 30
export var MAX_TURNS := 10

# Array containing the player nodes.
var players: Array

# Keeps track of whose turn it is.
var player_turn := 1
var winner

var camera_focus: Spatial

enum EDITOR_NODE_LINKING_DISPLAY {
	DISABLED,
	NEXT_NODES,
	PREV_NODES,
	ALL
}

# Path to the node, where Players start.
export var start_node: NodePath
export(EDITOR_NODE_LINKING_DISPLAY) var show_linking_type: int =\
		EDITOR_NODE_LINKING_DISPLAY.ALL

# Stores the value of steps that still need to be performed after a dice roll.
# Used for display.
var step_count := 0

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

	connect("next_player", self, "_on_Roll_pressed")
	connect("rolled", self, "do_step")
	connect("_calculate_step", self, "_step")
	players = get_tree().get_nodes_in_group("players")
	for p in players:
		p.player_id = i
		p.connect("walking_step", self, "animation_step", [p.player_id])
		i += 1
		if p.space == null and Global.new_game:
			p.space = get_node(start_node)
			p.translation = p.space.translation + PLAYER_TRANSLATION[i-2]

	Global.load_board_state(self)

	if player_turn <= players.size():
		camera_focus = players[player_turn - 1]

	$Screen/Cake.init(COOKIES_FOR_CAKE)

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
		$Screen/MinigameInformation.show_minigame_info(current_minigame, players)
	else:
		_on_Roll_pressed()

func relocate_cake():
	var cake_nodes: Array = get_tree().get_nodes_in_group("cake_nodes")
	# Randomly place cake spot on board.
	if cake_nodes.size() > 0:
		if Global.cake_space >= 0:
			cake_nodes[Global.cake_space].cake = false
		Global.cake_space = randi() % cake_nodes.size()
		var cake_node: Spatial = cake_nodes[Global.cake_space]
		cake_node.cake = true

# Function to check if the next player can roll or not.
func _on_Roll_pressed() -> void:
	if wait_for_animation:
		return

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

		var player = players[player_turn - 1]
		camera_focus = player
		var selected_item: Item = null

		if steps == null:
			$Screen/ItemSelection.select_item(player)
			selected_item = yield($Screen/ItemSelection, "item_selected")
		else:
			var dice = steps

			$Screen/Stepcounter.text = var2str(dice)
			step_count = dice

			emit_signal("rolled", player, dice)

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

				emit_signal("rolled", player, dice)

				# Show which number was rolled.
				$Screen/Dice.text = tr("CONTEXT_LABEL_PLAYER_ROLLED") %\
						[player.player_name, dice]
				$Screen/Dice.show()
			Item.TYPES.PLACABLE:
				$SelectSpaceHelper.select_space(player, selected_item.max_place_distance)
				var selected_space = yield($SelectSpaceHelper, "space_selected")
				selected_space.trap = selected_item
				selected_space.trap_player = player

				camera_focus = selected_space
				yield(get_tree().create_timer(1), "timeout")
				camera_focus = player

				# Use default dice.
				var dice = (randi() % 6) + 1

				$Screen/Stepcounter.text = var2str(dice)
				step_count = dice

				emit_signal("rolled", player, dice)

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

				emit_signal("rolled", player, dice)

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

		Global.turn += 1
		player_turn = 1
		yield(show_minigame_animation(), "completed")
		$Screen/MinigameInformation.show_minigame_info(current_minigame, players)

func create_choose_path_arrows(player) -> void:
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

func _step(player, previous_space: NodeBoard) -> void:
	# If there are multiple branches.
	if player.space.next.size() > 1:
		# Undo last step, to update it with a new location
		if not player.destination.empty():
			player.destination.pop_back()
			if not previous_space == player.space:
				update_space(previous_space)
				update_space(player.space)
			else:
				update_space(player.space)
			yield(player, "walking_ended")

		if not player.is_ai:
			create_choose_path_arrows(player)
			player.space = yield(self, "path_chosen")
		else:
			player.space = player.space.next[randi() % player.space.next.size()]
			yield(get_tree().create_timer(1), "timeout")
	elif player.space.next.size() == 1:
		player.space = player.space.next[0]

	# If player passes a cake-spot.
	if player.space.cake and player.cookies >= COOKIES_FOR_CAKE:
		update_space(previous_space)
		update_space(player.space)

		yield(player, "walking_ended")
		yield(buy_cake(player), "completed")

	# If player passes a shop space
	elif player.space.type == NodeBoard.NODE_TYPES.SHOP:
		update_space(previous_space)
		update_space(player.space)

		yield(player, "walking_ended")
		if not player.is_ai:
			$Screen/Shop.open_shop(player)
			yield($Screen/Shop, "shopping_completed")
		else:
			$Screen/Shop.ai_do_shopping(player)
	else:
		var offset: Vector3 = _get_player_offset(player.space)

		var walking_state = PLAYER.WalkingState.new()
		walking_state.space = player.space
		walking_state.position = player.space.translation + offset
		player.destination.append(walking_state)
	
	call_deferred("emit_signal", "_step_finished", player.space.is_visible_space())

func land_on_space(player):
	# Activate the item placed onto the node if any.
	if player.space.trap != null and player.space.trap.activate_trap(
		player, player.space.trap_player, self):
		player.space.trap = null

	# Lose cookies if you land on red space.
	match player.space.type:
		NodeBoard.NODE_TYPES.BLUE:
			player.cookies += 3
		NodeBoard.NODE_TYPES.RED:
			player.cookies -= 3
			if player.cookies < 0:
				player.cookies = 0
		NodeBoard.NODE_TYPES.GREEN:
			if len(self.get_signal_connection_list("trigger_event")) > 0:
				emit_signal("trigger_event", player, player.space)
				yield(self, "_event_completed")
			else:
				yield(get_tree().create_timer(1), "timeout")
		NodeBoard.NODE_TYPES.YELLOW:
			var rewards: Array = Global.MINIGAME_DUEL_REWARDS.values()

			Global.minigame_type = Global.MINIGAME_TYPES.DUEL
			current_minigame = Global.minigame_loader.get_random_duel()
			Global.minigame_duel_reward =\
					rewards[randi() % rewards.size()]

			player_turn += 1
			if not player.is_ai:
				yield(minigame_duel_reward_animation(), "completed")
				$Screen/DuelSelection.select(player, players)
			else:
				var players: Array = self.players.duplicate()
				players.remove(players.find(player))

				Global.minigame_teams = [[players[randi() %\
						players.size()].player_id], [player.player_id]]
				yield(minigame_duel_reward_animation(), "completed")
				yield(show_minigame_animation(), "completed")
				$Screen/MinigameInformation.show_minigame_info(current_minigame, players)
			return

	player_turn += 1
	wait_for_animation = false
	emit_signal("next_player")

# Moves a player num spaces forward and stops when a cake spot is encountered.
func do_step(player, num: int) -> void:
	# Adds each animation step to the player_board.gd script.
	# The last step is added during update_space(player.space).
	var previous_space = player.space
	var i = 0
	while i < num - 1:
		emit_signal("_calculate_step", player, previous_space)
		if yield(self, "_step_finished"):
			i += 1

	while true:
		emit_signal("_calculate_step", player, previous_space)
		if yield(self, "_step_finished"):
			# Reposition figures.
			player.destination.pop_back()
			update_space(previous_space)
			update_space(player.space)

			yield(player, "walking_ended")
			land_on_space(player)
			return

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
				not players[player_turn - 1].is_ai and wait_for_animation == false:
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
		if player.space == space:
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

# This method needs to be called, after an event triggered by landing on a
# green space is fully processed.
func continue() -> void:
	call_deferred("emit_signal", "_event_completed")

# Gets the reference to the node, on which the cake currently can be
# collected
func get_cake_space() -> NodeBoard:
	return get_tree().get_nodes_in_group("cake_nodes")[Global.cake_space]

func buy_cake(player: Spatial) -> void:
	if player.cookies >= COOKIES_FOR_CAKE:
		if not player.is_ai:
			$Screen/Cake.show_cake()
			if yield($Screen/Cake, "cake_shopping_completed"):
				relocate_cake()
		else:
			var cakes := int(player.cookies / COOKIES_FOR_CAKE)
			player.cakes += cakes
			player.cookies -= COOKIES_FOR_CAKE * cakes
			if cakes > 0:
				relocate_cake()
	yield(get_tree().create_timer(0), "timeout")

# If we end up on a green space at the end of turn, we execute the board event
# if the board event does a movement, we need to ignore it.
# That's the purpose of this variable.
var _ignore_animation_ended := false

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

func _on_choose_path_arrow_activated(arrow) -> void:
	emit_signal("path_chosen", arrow.next_node)
