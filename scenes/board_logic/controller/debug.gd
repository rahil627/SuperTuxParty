extends WindowDialog

enum STATES {
	ADD_COOKIES,
	ADD_CAKES,
	ADD_ITEMS,
	GOTO_PLAYER,
	MOVE
}

var players = null
var state = null
var selected_player = null

func setup():
	players = get_tree().get_nodes_in_group("players")
	
	for p in players:
		var button = Button.new()
		
		button.text = p.player_name
		button.add_font_override("font", preload("res://assets/fonts/button_font.tres"))
		button.connect("pressed", self, "_on_player_pressed", [p.player_id])
		
		$List/Players.add_child(button)
	
	var loader = PluginSystem.minigame_loader
	
	for minigame in loader.minigames:
		for type in minigame.type:
			var button = Button.new()
			
			button.text = minigame.filename.split('/')[-2]
			button.add_font_override("font", preload("res://assets/fonts/button_font.tres"))
			match type:
				"Duel":
					button.connect("pressed", self, "_on_minigame_pressed", [minigame, Global.MINIGAME_TYPES.DUEL])
					$List/Minigames/TabContainer/Duel/VBoxContainer.add_child(button)
				"1v3":
					button.connect("pressed", self, "_on_minigame_pressed", [minigame, Global.MINIGAME_TYPES.ONE_VS_THREE])
					$List/Minigames/TabContainer/"1v3"/VBoxContainer.add_child(button)
				"2v2":
					button.connect("pressed", self, "_on_minigame_pressed", [minigame, Global.MINIGAME_TYPES.TWO_VS_TWO])
					$List/Minigames/TabContainer/"2v2"/VBoxContainer.add_child(button)
				"FFA":
					button.connect("pressed", self, "_on_minigame_pressed", [minigame, Global.MINIGAME_TYPES.FREE_FOR_ALL])
					$List/Minigames/TabContainer/FFA/VBoxContainer.add_child(button)
				"NolokSolo":
					button.connect("pressed", self, "_on_minigame_pressed", [minigame, Global.MINIGAME_TYPES.NOLOK_SOLO])
					$List/Minigames/TabContainer/NolokSolo/VBoxContainer.add_child(button)
				"NolokCoop":
					button.connect("pressed", self, "_on_minigame_pressed", [minigame, Global.MINIGAME_TYPES.NOLOK_COOP])
					$List/Minigames/TabContainer/NolokCoop/VBoxContainer.add_child(button)
				"GnuSolo":
					button.connect("pressed", self, "_on_minigame_pressed", [minigame, Global.MINIGAME_TYPES.GNU_SOLO])
					$List/Minigames/TabContainer/GnuSolo/VBoxContainer.add_child(button)
				"GnuCoop":
					button.connect("pressed", self, "_on_minigame_pressed", [minigame, Global.MINIGAME_TYPES.GNU_COOP])
					$List/Minigames/TabContainer/GnuCoop/VBoxContainer.add_child(button)
				_:
					push_warning("No such minigame type: " + type)
	
	for item in PluginSystem.item_loader.get_loaded_items():
		var button = Button.new()
		
		button.text = item.split('/')[-2]
		button.add_font_override("font", preload("res://assets/fonts/button_font.tres"))
		button.connect("pressed", self, "_on_item_selected", [item])
		
		$List/Items.add_child(button)
	
	

func hide_lists():
	$List/Players.hide()
	$List/Minigames.hide()
	$List/Items.hide()
	$List/Inputs.hide()

func _on_Skip_pressed():
	Global.turn += 1
	$"../Turn".text = "Turn: " + var2str(Global.turn)

func _on_AddCookies_pressed():
	hide_lists()
	$List/Players.show()
	$List.popup()
	
	state = STATES.ADD_COOKIES

func _on_AddCake_pressed():
	hide_lists()
	$List/Players.show()
	$List.popup()
	
	state = STATES.ADD_CAKES

func _on_Move_pressed():
	hide_lists()
	$List/Inputs.show()
	$List.popup()
	
	state = STATES.MOVE

func _on_PlayersTurn_pressed():
	hide_lists()
	$List/Players.show()
	$List.popup()
	
	state = STATES.GOTO_PLAYER

func _on_Minigame_pressed():
	hide_lists()
	$List/Minigames.show()
	$List.popup()

func _on_player_pressed(id):
	var player = players[id - 1]
	
	if state == STATES.ADD_COOKIES:
		player.cookies += 5
	elif state == STATES.ADD_CAKES:
		player.cakes += 1
	elif state == STATES.ADD_ITEMS:
		selected_player = player
		$List/Players.hide()
		$List/Items.show()
	elif state == STATES.GOTO_PLAYER:
		$"../..".player_turn = player.player_id
	
	$"../..".update_player_info()

func _on_minigame_pressed(minigame, type):
	var controller = get_tree().get_nodes_in_group("Controller")[0]
	var state = Global.MinigameState.new()
	state.minigame_config = minigame
	state.minigame_type = type
	match type:
		Global.MINIGAME_TYPES.FREE_FOR_ALL, Global.MINIGAME_TYPES.NOLOK_COOP, Global.MINIGAME_TYPES.GNU_COOP:
			state.minigame_teams = [[1, 2, 3, 4], []]
		Global.MINIGAME_TYPES.TWO_VS_TWO:
			state.minigame_teams = [[1, 3], [2, 4]]
		Global.MINIGAME_TYPES.ONE_VS_THREE:
			# Randomly place player to either solo or group team
			# TODO: Add a dialog to choose which side to join
			if randi() % 2 == 0:
				state.minigame_teams = [[1, 2, 3], [4]]
			else:
				state.minigame_teams = [[2, 3, 4], [1]]
		Global.MINIGAME_TYPES.DUEL:
			state.minigame_teams = [[1], [2]]
			
			# Set a minigame reward or else, the game will crash when returning
			# to the board
			Global.minigame_reward = Global.MinigameReward.new()
			Global.minigame_reward.duel_reward = Global.MINIGAME_DUEL_REWARDS.TEN_COOKIES
		Global.MINIGAME_TYPES.NOLOK_SOLO, Global.MINIGAME_TYPES.GNU_SOLO:
			state.minigame_teams = [[1], []]
	
	if type == Global.MINIGAME_TYPES.GNU_SOLO:
		var items: Array = PluginSystem.item_loader.get_buyable_items()
		var reward: Item = load(items[randi() % len(items)]).new()
		Global.minigame_reward = Global.MinigameReward.new()
		Global.minigame_reward.gnu_solo_item_reward = reward
	
	controller.show_minigame_info(state)
	controller.hide_splash()
	hide()
	$List.hide()

func _on_Item_pressed():
	hide_lists()
	$List/Players.show()
	$List.popup()
	
	state = STATES.ADD_ITEMS

func _on_item_selected(item):
	selected_player.give_item(load(item).new())
	$List.hide()
	hide()

func _on_Ok_pressed():
	var controller = get_tree().get_nodes_in_group("Controller")[0]
	
	match state:
		STATES.MOVE:
			var steps = int($List/Inputs/Number.value)
			controller.roll(steps)
	
	$List.hide()
	hide()
