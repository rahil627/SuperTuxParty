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
signal _camera_focus_aquired

# If multiple players get on one space, this array decides the translation of
# each.
const PLAYER_TRANSLATION = [Vector3(0, 0, -0.75), Vector3(0.75, 0, 0),
		Vector3(0, 0, 0.75), Vector3(-0.75, 0, 0)]
const EMPTY_SPACE_PLAYER_TRANSLATION = Vector3(0, 0.05, 0)
const CAMERA_SPEED = 6

const PLAYER = preload("res://scenes/board_logic/player_board/player_board.gd")
const PLACEMENT_COLORS := [Color("#FFD700"), Color("#C9C0BB"), Color("#CD7F32"), Color(0.3, 0.3, 0.3)]

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

func _ready() -> void:
	# Give each player a unique id.
	var i = 1

	connect("next_player", self, "_on_Roll_pressed")
	connect("rolled", self, "do_step")
	connect("_calculate_step", self, "_step")
	players = get_tree().get_nodes_in_group("players")
	for p in players:
		p.player_id = i
		# Update the "spaces to walk" counter
		p.connect("walking_step", self, "animation_step", [p.player_id])
		# Play a short fx when passing a step
		p.connect("walking_step", self, "play_space_step_sfx", [p.player_id])
		i += 1
		if p.space == null and Global.new_game:
			p.space = get_node(start_node)
			p.translation = p.space.translation + PLAYER_TRANSLATION[i-2]

	Global.load_board_state(self)

	if player_turn <= players.size():
		camera_focus = players[player_turn - 1]

	# Initialize GUI.
	if player_turn <= Global.amount_of_players:
		$Screen/Turn.text = tr("CONTEXT_LABEL_TURN_NUM").format({"turn": Global.turn, "total": Global.overrides.max_turns})
		$Screen/Dice.text = tr("CONTEXT_LABEL_ROLL_PLAYER").format(
				{"name": players[player_turn - 1].player_name})

	update_player_info()

	$Screen/Debug.setup()
	if Global.minigame_summary:
		# Do some moderation according to the last minigame type being played
		match Global.minigame_summary.minigame_type:
			Global.MINIGAME_TYPES.GNU_SOLO:
				var player_id = player_turn
				if Global.minigame_summary.placement:
					$Screen/SpeechDialog.show_dialog(tr("CONTEXT_GNU_NAME"), preload("res://scenes/board_logic/controller/icons/gnu_icon.png"), tr("CONTEXT_GNU_SOLO_VICTORY"), player_id)
					yield($Screen/SpeechDialog, "dialog_finished")
					players[player_id - 1].give_item(Global.minigame_summary.reward)
				else:
					$Screen/SpeechDialog.show_dialog(tr("CONTEXT_GNU_NAME"), preload("res://scenes/board_logic/controller/icons/gnu_icon.png"), tr("CONTEXT_GNU_SOLO_LOSS"), player_id)
					yield($Screen/SpeechDialog, "dialog_finished")
				player_turn += 1
			Global.MINIGAME_TYPES.GNU_COOP:
				var player_id = player_turn
				if Global.minigame_summary.placement:
					$Screen/SpeechDialog.show_dialog(tr("CONTEXT_GNU_NAME"), preload("res://scenes/board_logic/controller/icons/gnu_icon.png"), tr("CONTEXT_GNU_COOP_VICTORY"), player_id)
				else:
					$Screen/SpeechDialog.show_dialog(tr("CONTEXT_GNU_NAME"), preload("res://scenes/board_logic/controller/icons/gnu_icon.png"), tr("CONTEXT_GNU_COOP_LOSS"), player_id)
				yield($Screen/SpeechDialog, "dialog_finished")
				player_turn += 1
			Global.MINIGAME_TYPES.NOLOK_SOLO:
				var player_id = player_turn
				if Global.minigame_summary.placement:
					$Screen/SpeechDialog.show_dialog(tr("CONTEXT_NOLOK_NAME"), preload("res://scenes/board_logic/controller/icons/nolokicon.png"), tr("CONTEXT_NOLOK_SOLO_VICTORY"), player_id)
				else:
					$Screen/SpeechDialog.show_dialog(tr("CONTEXT_NOLOK_NAME"), preload("res://scenes/board_logic/controller/icons/nolokicon.png"), tr("CONTEXT_NOLOK_SOLO_LOSS"), player_id)
				yield($Screen/SpeechDialog, "dialog_finished")
				player_turn += 1
			Global.MINIGAME_TYPES.NOLOK_COOP:
				var player_id = player_turn
				if Global.minigame_summary.placement:
					$Screen/SpeechDialog.show_dialog(tr("CONTEXT_NOLOK_NAME"), preload("res://scenes/board_logic/controller/icons/nolokicon.png"), tr("CONTEXT_NOLOK_COOP_VICTORY"), player_id)
				else:
					$Screen/SpeechDialog.show_dialog(tr("CONTEXT_NOLOK_NAME"), preload("res://scenes/board_logic/controller/icons/nolokicon.png"), tr("CONTEXT_NOLOK_COOP_LOSS"), player_id)
				yield($Screen/SpeechDialog, "dialog_finished")
				player_turn += 1

	if Global.storage.get_value("Controller", "show_tutorial", true):
		if yield(ask_yes_no(tr("CONTEXT_SHOW_TUTORIAL"), false), "completed"):
			yield(show_tutorial(), "completed")
		Global.storage.set_value("Controller", "show_tutorial", false)
		Global.save_storage()

	if not Global.cake_space and not winner:
		yield(relocate_cake(), "completed")

	if not $Screen/MinigameInformation.visible:
		_on_Roll_pressed()

func announce(text: String):
	var current_player = players[player_turn - 1]
	var sara_icon := preload("res://scenes/board_logic/controller/icons/sara.png")
	$Screen/SpeechDialog.show_dialog(tr("CONTEXT_SPEAKER_SARA"), sara_icon, text, current_player.player_id)
	yield($Screen/SpeechDialog, "dialog_finished")

func ask_yes_no(text: String, ai_default: bool) -> bool:
	var current_player = players[player_turn - 1]
	var sara_icon := preload("res://scenes/board_logic/controller/icons/sara.png")
	$Screen/SpeechDialog.show_accept_dialog(tr("CONTEXT_SPEAKER_SARA"), sara_icon, text, current_player.player_id, ai_default)
	return yield($Screen/SpeechDialog, "dialog_option_taken")

func query_range(text: String, minimum: int, maximum: int, start_value: int, ai_default: int) -> int:
	var current_player = players[player_turn - 1]
	var sara_icon := preload("res://scenes/board_logic/controller/icons/sara.png")
	$Screen/SpeechDialog.show_query_dialog(tr("CONTEXT_SPEAKER_SARA"), sara_icon, text, current_player.player_id, minimum, maximum, start_value, ai_default)
	return yield($Screen/SpeechDialog, "dialog_option_taken")

func show_tutorial():
	yield(announce(tr("CONTEXT_TUTORIAL_DICE")), "completed")
	yield(announce(tr("CONTEXT_TUTORIAL_SPACES_NORMAL")), "completed")
	yield(announce(tr("CONTEXT_TUTORIAL_SPACES_SPECIAL")), "completed")
	yield(announce(tr("CONTEXT_TUTORIAL_MINIGAMES")), "completed")
	yield(announce(tr("CONTEXT_TUTORIAL_MINIGAMES_FFA")), "completed")
	yield(announce(tr("CONTEXT_TUTORIAL_MINIGAMES_2V2")), "completed")
	yield(announce(tr("CONTEXT_TUTORIAL_MINIGAMES_1V3")), "completed")
	yield(announce(tr("CONTEXT_TUTORIAL_MINIGAMES_SPECIAL")), "completed")
	yield(announce(tr("CONTEXT_TUTORIAL_COOKIES")), "completed")
	yield(announce(tr("CONTEXT_TUTORIAL_CAKES")), "completed")
	yield(announce(tr("CONTEXT_TUTORIAL_END")), "completed")

func relocate_cake() -> void:
	var cake_nodes: Array = get_tree().get_nodes_in_group("cake_nodes")
	# Randomly place cake spot on board.
	if cake_nodes.size() > 0:
		if Global.cake_space:
			var old_node = get_cake_space()
			yield(old_node.play_cake_collection_animation(), "completed")
			old_node.cake = false
			if cake_nodes.size() > 1:
				cake_nodes.remove(cake_nodes.find(old_node))
		var new_node: Node = cake_nodes[randi() % cake_nodes.size()]
		Global.cake_space = get_path_to(new_node)
		new_node.cake = true

		var old_focus = camera_focus
		camera_focus = new_node
		yield(self, "_camera_focus_aquired")
		yield(announce(tr("CONTEXT_CAKE_PLACED")), "completed")
		camera_focus = old_focus
		yield(self, "_camera_focus_aquired")
	yield(get_tree().create_timer(0.0), "timeout")

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

		var player = players[player_turn - 1]
		var character = Global.players[player_turn - 1].character
		$Screen/Splash/Background/Player.texture =\
				PluginSystem.character_loader.load_character_splash(character)
		$Screen/Splash.play("show")

		if player.is_ai:
			get_tree().create_timer(1).connect("timeout", self, "_on_Roll_pressed")
		else:
			$Screen/Roll.show()

		camera_focus = player

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
			$Screen/Dice.text = tr("CONTEXT_LABEL_PLAYER_ROLLED").format(
					{"name": player.player_name, "value": dice})
			$Screen/Dice.show()
			return

		match selected_item.type:
			Item.TYPES.DICE:
				var dice = selected_item.activate(player, self)

				dice = max(dice + player.get_total_roll_modifier(), 0)
				player.roll_modifiers_count_down()

				$Screen/Stepcounter.text = var2str(dice)
				step_count = dice

				emit_signal("rolled", player, dice)

				# Show which number was rolled.
				$Screen/Dice.text = tr("CONTEXT_LABEL_PLAYER_ROLLED").format(
						{"name": player.player_name, "value": dice})
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
				$Screen/Dice.text = tr("CONTEXT_LABEL_PLAYER_ROLLED").format(
						{"name": player.player_name, "value": dice})
				$Screen/Dice.show()
			Item.TYPES.ACTION:
				selected_item.activate(player, self)

				# Use default dice.
				var dice = (randi() % 6) + 1

				$Screen/Stepcounter.text = var2str(dice)
				step_count = dice

				emit_signal("rolled", player, dice)

				# Show which number was rolled
				$Screen/Dice.text = tr("CONTEXT_LABEL_PLAYER_ROLLED").format(
						{"name": player.player_name, "value": dice})
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

		var state = Global.MinigameState.new()
		state.minigame_teams = [blue_team, red_team]

		match [blue_team.size(), red_team.size()]:
			[4, 0]:
				state.minigame_type = Global.MINIGAME_TYPES.FREE_FOR_ALL
				state.minigame_config = PluginSystem.minigame_loader.get_random_ffa()
			[3, 1]:
				state.minigame_type = Global.MINIGAME_TYPES.ONE_VS_THREE
				state.minigame_config = PluginSystem.minigame_loader.get_random_1v3()
			[2, 2]:
				state.minigame_type = Global.MINIGAME_TYPES.TWO_VS_TWO
				state.minigame_config = PluginSystem.minigame_loader.get_random_2v2()

		Global.turn += 1
		player_turn = 1
		yield(show_minigame_animation(state), "completed")
		show_minigame_info(state)

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
	if player.space.cake:
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
			yield(get_tree().create_timer(1), "timeout")
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

			var minigame = PluginSystem.minigame_loader.get_random_duel()

			var state = Global.MinigameState.new()
			state.minigame_type = Global.MINIGAME_TYPES.DUEL
			state.minigame_config = minigame
			
			Global.minigame_reward = Global.MinigameReward.new()
			Global.minigame_reward.duel_reward = \
					rewards[randi() % rewards.size()]

			player_turn += 1
			if not player.is_ai:
				yield(minigame_duel_reward_animation(), "completed")
				$Screen/DuelSelection.select(state, player, players)
			else:
				var players: Array = self.players.duplicate()
				players.remove(players.find(player))

				state.minigame_teams = [[players[randi() %\
						players.size()].player_id], [player.player_id]]
				yield(minigame_duel_reward_animation(), "completed")
				yield(show_minigame_animation(state), "completed")
				show_minigame_info(state)
			return
		NodeBoard.NODE_TYPES.NOLOK:
			$Screen/SpeechDialog.show_dialog(tr("CONTEXT_NOLOK_NAME"), preload("res://scenes/board_logic/controller/icons/nolokicon.png"), tr("CONTEXT_NOLOK_EVENT_START"), player.player_id)
			yield($Screen/SpeechDialog, "dialog_finished")

			var actions = Global.NOLOK_ACTION_TYPES
			var type = actions.values()[randi() % actions.size()]
			
			var state = null
			var players = []
			
			var dialog_text
			
			match type:
				Global.NOLOK_ACTION_TYPES.SOLO_MINIGAME:
					dialog_text = tr("CONTEXT_NOLOK_MINIGAME_SOLO_MODERATION")
					$Screen/NolokSelection/Content/Selection.text = "CONTEXT_NOLOK_MINIGAME_SOLO"
					state = Global.MinigameState.new()
					state.minigame_type = Global.MINIGAME_TYPES.NOLOK_SOLO
					state.minigame_config = PluginSystem.minigame_loader.get_random_nolok_solo()
					players.append(player.player_id)
				Global.NOLOK_ACTION_TYPES.COOP_MINIGAME:
					dialog_text = tr("CONTEXT_NOLOK_MINIGAME_COOP_MODERATION")
					$Screen/NolokSelection/Content/Selection.text = "CONTEXT_NOLOK_MINIGAME_COOP"
					state = Global.MinigameState.new()
					state.minigame_type = Global.MINIGAME_TYPES.NOLOK_COOP
					state.minigame_config = PluginSystem.minigame_loader.get_random_nolok_coop()
					for player in self.players:
						players.append(player.player_id)
				Global.NOLOK_ACTION_TYPES.BOARD_EFFECT:
					# Random negative effect
					match randi() % 2:
						0:
							# Let the player loose cookies depending on rank
							var cookies = [15, 10, 5, 5]
							var rank = _get_player_placement(player)
							
							var stolen_cookies = min(cookies[rank - 1], player.cookies)
							
							# Give them to the last player (that is not yourself)
							var target = null
							for p in self.players:
								if (not target or target.cakes > p.cakes or (target.cakes == p.cakes and target.cookies > p.cookies)) and p != player:
									target = p
							
							player.cookies -= stolen_cookies
							target.cookies += stolen_cookies
							dialog_text = tr("CONTEXT_NOLOK_LOSE_COOKIES_MODERATION").format({"amount": stolen_cookies, "player": target.player_name})
							$Screen/NolokSelection/Content/Selection.text = "CONTEXT_NOLOK_LOSE_COOKIES"
						1:
							# The next 5 rolls of the player are reduced by 2
							player.add_roll_modifier(-2, 5)
							dialog_text = tr("CONTEXT_NOLOK_ROLL_MODIFIER_MODERATION").format({"amount": 2, "duration": 5})
							$Screen/NolokSelection/Content/Selection.text = "CONTEXT_NOLOK_ROLL_MODIFIER"

			$Screen/NolokSelection/AnimationPlayer.play("show")
			yield($Screen/NolokSelection/AnimationPlayer, "animation_finished")
			$Screen/NolokSelection.hide()

			$Screen/SpeechDialog.show_dialog(tr("CONTEXT_NOLOK_NAME"), preload("res://scenes/board_logic/controller/icons/nolokicon.png"), dialog_text, player.player_id)
			yield($Screen/SpeechDialog, "dialog_finished")

			if state:
				state.minigame_teams = [players, []]
				yield(show_minigame_animation(state), "completed")
				show_minigame_info(state)
				return
		NodeBoard.NODE_TYPES.GNU:
			$Screen/SpeechDialog.show_dialog(tr("CONTEXT_GNU_NAME"), preload("res://scenes/board_logic/controller/icons/gnu_icon.png"), tr("CONTEXT_GNU_EVENT_START"), player.player_id)
			yield($Screen/SpeechDialog, "dialog_finished")
			
			var actions: Array = Global.GNU_ACTION_TYPES.values()
			var type = actions[randi() % actions.size()]
			
			var state = Global.MinigameState.new()
			var players := []
			var dialog_text := ""
			
			match type:
				Global.GNU_ACTION_TYPES.SOLO_MINIGAME:
					var items: Array = PluginSystem.item_loader.get_buyable_items()
					var reward: Item = load(items[randi() % len(items)]).new()
					dialog_text = tr("CONTEXT_GNU_MINIGAME_SOLO_MODERATION").format({"reward": reward.name})
					$Screen/GNUSelection/Content/Selection.text = "CONTEXT_GNU_MINIGAME_SOLO"

					state.minigame_type = Global.MINIGAME_TYPES.GNU_SOLO
					state.minigame_config = PluginSystem.minigame_loader.get_random_gnu_solo()

					Global.minigame_reward = Global.MinigameReward.new()
					Global.minigame_reward.gnu_solo_item_reward = reward

					players.push_back(player.player_id)
				Global.GNU_ACTION_TYPES.COOP_MINIGAME:
					dialog_text = tr("CONTEXT_GNU_MINIGAME_COOP_MODERATION")
					$Screen/GNUSelection/Content/Selection.text = "CONTEXT_GNU_MINIGAME_COOP"
					state.minigame_type = Global.MINIGAME_TYPES.GNU_COOP
					state.minigame_config = PluginSystem.minigame_loader.get_random_gnu_coop()
					for player in self.players:
						players.push_back(player.player_id)

			$Screen/GNUSelection/AnimationPlayer.play("show")
			yield($Screen/GNUSelection/AnimationPlayer, "animation_finished")
			$Screen/GNUSelection.hide()

			$Screen/SpeechDialog.show_dialog(tr("CONTEXT_GNU_NAME"), preload("res://scenes/board_logic/controller/icons/gnu_icon.png"), dialog_text, player.player_id)
			yield($Screen/SpeechDialog, "dialog_finished")

			state.minigame_teams = [players, []]
			yield(show_minigame_animation(state), "completed")
			show_minigame_info(state)
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

func show_minigame_info(state) -> void:
	$Screen/MinigameInformation.show_minigame_info(state, players)

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

func _get_player_placement(p: Spatial) -> int:
	var placement := 1
	for p2 in players:
		if p2.cakes > p.cakes or p2.cakes == p.cakes and p2.cookies > p.cookies:
			placement += 1
	
	return placement

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
	return get_node(Global.cake_space) as NodeBoard

func buy_cake(player: Spatial) -> void:
	if player.cookies >= COOKIES_FOR_CAKE:
		if yield(ask_yes_no(tr("CONTEXT_CAKE_WANT_BUY"), true), "completed"):
			var max_cakes := int(player.cookies / COOKIES_FOR_CAKE)
			var amount := max_cakes
			if amount != 1:
				amount = yield(query_range(tr("CONTEXT_CAKE_BUY_AMOUNT"), 1, max_cakes, max_cakes, max_cakes), "completed")
			player.cakes += amount
			player.cookies -= COOKIES_FOR_CAKE * amount
			yield(get_tree().create_timer(0.5), "timeout")
			var text := tr("CONTEXT_CAKE_COLLECTED"). \
				format({"player": player.name, "amount": amount})
			yield(announce(text), "completed")
			yield(relocate_cake(), "completed")
	else:
		yield(announce(tr("CONTEXT_CAKE_CANT_AFFORD")), "completed")
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

func play_space_step_sfx(space: NodeBoard, player_id: int) -> void:
	if player_id == player_turn and space.is_visible_space():
		$StepFX.play()

func _process(delta: float) -> void:
	if camera_focus != null:
		var dir: Vector3 = camera_focus.translation - translation
		if dir.length() > 0.01:
			translation +=\
					CAMERA_SPEED * dir.length() * dir.normalized() * delta
		else:
			emit_signal("_camera_focus_aquired")

# Function that updates the player info shown in the GUI.
func update_player_info() -> void:
	var i := 1

	for p in players:
		var placement = _get_player_placement(p)

		var pos: Label = get_node("Screen/PlayerInfo%d" % i).get_node("Name/Position")
		pos.text = str(placement)
		pos.set("custom_colors/font_color", PLACEMENT_COLORS[placement - 1])
		var info = get_node("Screen/PlayerInfo" + str(i))
		info.get_node("Name/Player").text = p.player_name

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

func show_minigame_animation(state) -> void:
	var i := 1
	for team in state.minigame_teams:
		for player_id in team:
			var character = Global.players[player_id - 1].character
			var texture = PluginSystem.character_loader.load_character_icon(character)
			$Screen/MinigameTypeAnimation/Root.get_node("Player" + str(i)).texture = texture
			i += 1

	match state.minigame_type:
		Global.MINIGAME_TYPES.FREE_FOR_ALL:
			$Screen/MinigameTypeAnimation.play("FFA")
		Global.MINIGAME_TYPES.ONE_VS_THREE:
			$Screen/MinigameTypeAnimation.play("1v3")
		Global.MINIGAME_TYPES.TWO_VS_TWO:
			$Screen/MinigameTypeAnimation.play("2v2")
		Global.MINIGAME_TYPES.DUEL:
			$Screen/MinigameTypeAnimation.play("Duel")

	$Screen/Dice.hide()

	if $Screen/MinigameTypeAnimation.is_playing():
		yield($Screen/MinigameTypeAnimation, "animation_finished")
	else:
		yield(get_tree().create_timer(0), "timeout")

func minigame_duel_reward_animation() -> void:
	var name: String
	for key in Global.MINIGAME_DUEL_REWARDS.keys():
		if Global.MINIGAME_DUEL_REWARDS[key] == Global.minigame_reward.duel_reward:
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
