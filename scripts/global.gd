extends Node

# Information about a player that needs to be saved when a scene change occurs
class PlayerState:
	var player_id = 0
	var player_name = ""
	var is_ai = false
	var character = ""
	var cookies = 0
	var cookies_gui = 0
	var cakes = 0
	var items = []
	
	# Which space on the board the player is standing on
	var space = null

const MINIGAME_REWARD_SCREEN_PATH_FFA = "res://scenes/board_logic/controller/rewardscreens/ffa.tscn";
const MINIGAME_REWARD_SCREEN_PATH_DUEL = "res://scenes/board_logic/controller/rewardscreens/duel.tscn";
const MINIGAME_REWARD_SCREEN_PATH_1V3 = "res://scenes/board_logic/controller/rewardscreens/1v3.tscn";
const MINIGAME_REWARD_SCREEN_PATH_2V2 = "res://scenes/board_logic/controller/rewardscreens/2v2.tscn";

var plugin_system = preload("res://scripts/plugin_system.gd").new()

var board_loader = preload("res://scripts/board_loader.gd").new()
var minigame_loader = preload("res://scripts/minigame_loader.gd").new()
var character_loader = preload("res://scripts/character_loader.gd").new()
var item_loader = preload("res://scripts/item_loader.gd").new()

var SaveGameLoader = preload("res://savegames/savegames.gd")
var savegame_loader = SaveGameLoader.new()

# linear, 1st: 15, 2nd: 10, 3rd: 5, 4th: 0
# winner_only, 1st: 10, 2nd-4th: 0
enum AWARD_TYPE {
	LINEAR,
	WINNER_ONLY
}

enum MINIGAME_DUEL_REWARDS {
	TEN_COOKIES,
	ONE_CAKE
}

enum JOYPAD_DISPLAY_TYPE {
	NUMBERS,
	XBOX,
	NINTENDO_DS,
	PLAYSTATION
}

enum MINIGAME_TYPES {
	DUEL,
	ONE_VS_THREE,
	TWO_VS_TWO,
	FREE_FOR_ALL
}

var joypad_display = JOYPAD_DISPLAY_TYPE.NUMBERS

var amount_of_players = 4

# Is true if you exit to menu from inside the game
var quit_to_menu = false

# Pause game if the window loses focus
var pause_window_unfocus = true

# Mute game if the window loses focus
var mute_window_unfocus = true
var _was_muted = false

# Option to choose how players are awarded after completing a mini-game
var award = AWARD_TYPE.LINEAR

# Resource location of the current board
var current_board

# Pointer to top-level node in current scene
var current_scene = null
var max_turns = 5

# Stops the controller from loading information when starting a new game
var new_game = true
var cookie_space = 0
var players = [PlayerState.new(), PlayerState.new(), PlayerState.new(), PlayerState.new()]
var turn = 1
var player_turn = 1

# Stores where a trap is placed and what item and player created it
var trap_states = []

# The minigame to return to in "try minigame" mode
# If it is null, then no minigame is tried and the next turn resumes
var current_minigame = null
var minigame_type
var minigame_teams

var minigame_duel_reward

var current_savegame = null
var is_new_savegame = false

# Stores the last placement (not changed when you press "try")
# Used in rewardscreen.gd
var placement

func _ready():
	randomize()
	var root = get_tree().get_root()
	current_scene = root.get_child(root.get_child_count() -1)
	
	savegame_loader.read_savegames()

func _notification(what):
	match what:
		MainLoop.NOTIFICATION_WM_FOCUS_IN:
			if mute_window_unfocus:
				if not _was_muted:
					AudioServer.set_bus_mute(0, false)
				else:
					_was_muted = false
		MainLoop.NOTIFICATION_WM_FOCUS_OUT:
			if mute_window_unfocus:
				if not AudioServer.is_bus_mute(0):
					AudioServer.set_bus_mute(0, true)
				else:
					_was_muted = true

func load_board(board, names, characters, human_players):
	for i in range(characters.size()):
		players[i].player_name = names[i]
		players[i].character = characters[i]
		if i >= human_players:
			players[i].is_ai = true
	current_board = board;
	call_deferred("_goto_scene_ingame", board)

# Goto a specific scene without saving player states
func goto_scene(path):
	call_deferred("_goto_scene", path)

# Internal function for actually changing scene without saving any game state
func _goto_scene(path):
	current_scene.free()
	
	var s = load(path)
	
	current_scene = s.instance()
	
	get_tree().get_root().add_child(current_scene)
	get_tree().set_current_scene(current_scene)

# Internal function for actually changing scene while handling player objects
func _goto_scene_ingame(path):
	current_scene.free()
	
	var loader = ResourceLoader.load_interactive(path)
	
	if loader == null:
		print("Error: could not load scene " + path)
	else:
		loader.wait()
	
	var s = loader.get_resource()
	
	current_scene = s.instance()
	
	if minigame_teams == null:
		for i in range(players.size()):
			var player = current_scene.get_node("Player" + var2str(i+1))
			
			var new_model = load(character_loader.get_character_path(players[i].character)).instance()
			new_model.set_name("Model")
			
			var old_model = player.get_node("Model")
			new_model.translation = old_model.translation
			new_model.scale = old_model.scale
			new_model.rotation = old_model.rotation
			old_model.replace_by(new_model, true)
			
			player.is_ai = players[i].is_ai
			
			if player.has_node("Shape"):
				var collision_shape = player.get_node("Shape")
				collision_shape.translation += new_model.translation
				collision_shape.shape = load(character_loader.get_collision_shape_path(players[i].character))
	else:
		var i = 1
		for team in minigame_teams:
			for player_id in team:
				var player = current_scene.get_node("Player" + var2str(i))
				
				var new_model = load(character_loader.get_character_path(players[player_id - 1].character)).instance()
				new_model.set_name("Model")
				
				var old_model = player.get_node("Model")
				new_model.translation = old_model.translation
				new_model.scale = old_model.scale
				new_model.rotation = old_model.rotation
				old_model.replace_by(new_model, true)
				
				player.is_ai = players[player_id - 1].is_ai
				player.player_id = player_id
				
				if player.has_node("Shape"):
					var collision_shape = player.get_node("Shape")
					collision_shape.translation += new_model.translation
					collision_shape.shape = load(character_loader.get_collision_shape_path(players[player_id - 1].character))
				
				i += 1
			
			# Remove unnecessary players
		while i <= Global.amount_of_players:
			var player = current_scene.get_node("Player" + var2str(i))
			current_scene.remove_child(player)
			player.queue_free()
			i += 1
	
	get_tree().get_root().add_child(current_scene)
	get_tree().set_current_scene(current_scene)

func load_board_from_savegame(savegame):
	current_savegame = savegame
	is_new_savegame = false
	new_game = false
	
	current_board = savegame.board_path;
	for i in range(amount_of_players):
		players[i].player_id = i + 1
		players[i].player_name = savegame.players[i].player_name
		players[i].is_ai = savegame.players[i].is_ai
		players[i].space = savegame.players[i].space
		players[i].character = savegame.players[i].character
		players[i].cookies = int(savegame.players[i].cookies)
		players[i].cakes = int(savegame.players[i].cakes)
		players[i].items = savegame.players[i].items
	
	cookie_space = int(savegame.cookie_space)
	current_minigame = savegame.current_minigame
	player_turn = int(current_savegame.player_turn)
	award = int(savegame.award_type)
	
	trap_states = savegame.trap_states.duplicate()
	
	call_deferred("_goto_scene_ingame", current_board)

# Change scene to one of the mini-games
func goto_minigame(minigame, try = false):
	
	# Current player nodes
	var r_players = get_tree().get_nodes_in_group("players")
	if try:
		current_minigame = minigame
	
	player_turn = get_tree().get_nodes_in_group("Controller")[0].player_turn
	
	trap_states = []
	for trap in get_tree().get_nodes_in_group("trap"):
		var state = { node = trap.get_path(), item = trap.trap, player = trap.trap_player.get_path() }
		
		trap_states.push_back(state)
	
	# Save player states in the array 'players'
	for i in range(r_players.size()):
		players[i].player_id = r_players[i].player_id
		players[i].player_name = r_players[i].player_name
		players[i].cookies = r_players[i].cookies
		players[i].cookies_gui = r_players[i].cookies_gui
		players[i].cakes = r_players[i].cakes
		players[i].space = r_players[i].space.get_path()
		
		players[i].items = duplicate_items(r_players[i].items)
	
	call_deferred("_goto_scene_ingame", minigame.scene_path)

func duplicate_items(items):
	var list = []
	for item in items:
		list.push_back(inst2dict(item))
	
	return list

func deduplicate_items(items):
	var list = []
	for item in items:
		list.push_back(dict2inst(item))
	
	return list

# Go back to board from mini-game, placement is an array with the players' id:s
func goto_board(placement):
	if current_minigame == null:
		# Only award if it's not a test
		self.placement = placement
		match minigame_type:
			MINIGAME_TYPES.FREE_FOR_ALL:
				match award:
					AWARD_TYPE.LINEAR:
						for i in range(amount_of_players):
							players[placement[i] - 1].cookies += 15 - (i * 5)
					AWARD_TYPE.WINNER_ONLY:
						players[placement[0] - 1].cookies += 10
				call_deferred("_goto_scene", MINIGAME_REWARD_SCREEN_PATH_FFA)
			MINIGAME_TYPES.TWO_VS_TWO:
				for player_id in minigame_teams[placement]:
					players[player_id - 1].cookies += 10
				call_deferred("_goto_scene", MINIGAME_REWARD_SCREEN_PATH_2V2)
			MINIGAME_TYPES.ONE_VS_THREE:
				for player_id in minigame_teams[placement]:
					# Has the solo player won?
					if placement == 1:
						players[player_id - 1].cookies += 10
					else:
						players[player_id - 1].cookies += 5
				call_deferred("_goto_scene", MINIGAME_REWARD_SCREEN_PATH_1V3)
			MINIGAME_TYPES.DUEL:
				match minigame_duel_reward:
					MINIGAME_DUEL_REWARDS.TEN_COOKIES:
						var other_player_cookies = min(players[placement[1] - 1].cookies, 10)
						players[placement[0] - 1].cookies += other_player_cookies
						players[placement[1] - 1].cookies -= other_player_cookies
					MINIGAME_DUEL_REWARDS.ONE_CAKE:
						var other_player_cakes = min(players[placement[1] - 1].cakes, 1)
						players[placement[0] - 1].cakes += other_player_cakes
						players[placement[1] - 1].cakes -= other_player_cakes
				call_deferred("_goto_scene", MINIGAME_REWARD_SCREEN_PATH_DUEL)
	else:
		call_deferred("_goto_scene_ingame", current_board)

func load_board_state():
	var r_players = get_tree().get_nodes_in_group("players") # Current player nodes
	
	if !new_game:
		
		# Place cake spot back on the board
		var cake_nodes = get_tree().get_nodes_in_group("cake_nodes")
		var cake_node = cake_nodes[cookie_space]
		
		cake_node.cake = true
		cake_node.get_node("Cake").visible = true
		
		var controller = current_scene.get_node("Controller")
		controller.current_minigame = current_minigame
		current_minigame = null
		
		controller.player_turn = player_turn
		
		# Replace traps
		for trap in trap_states:
			var node = get_node(trap.node)
			node.trap = trap.item
			node.trap_player = get_node(trap.player)
		
		# Load player states from the array 'players'
		for i in range(r_players.size()):
			r_players[i].player_id = players[i].player_id
			r_players[i].player_name = players[i].player_name
			r_players[i].cookies = players[i].cookies
			r_players[i].cookies_gui = players[i].cookies_gui
			r_players[i].cakes = players[i].cakes
			r_players[i].space = current_scene.get_node(players[i].space)
			r_players[i].is_ai = players[i].is_ai
			
			r_players[i].items = deduplicate_items(players[i].items)
			
			for item in r_players[i].items:
				# Load missing icons, material, etc
				item.recreate_state()
			
			# Move piece to the right space, place them to different position on the same space
			var num = controller.get_players_on_space(r_players[i].space)
			var translation = controller.EMPTY_SPACE_PLAYER_TRANSLATION
			
			# Fix first player sitting in the middle of the space
			if num == 2:
				for x in range(i):
					if r_players[i].space == r_players[x].space:
						r_players[x].translation = r_players[x].space.translation + controller.PLAYER_TRANSLATION[0]
			
			if num > 1:
				translation = controller.PLAYER_TRANSLATION[num - 1]
			r_players[i].translation = r_players[i].space.translation + translation
			
			if i == controller.player_turn:
				controller.translation = r_players[i].translation # Move camera to player 1
	else:
		for i in range(r_players.size()):
			r_players[i].player_name = players[i].player_name
			r_players[i].is_ai = players[i].is_ai
		
		# Randomly place cake spot on board
		var cake_nodes = get_tree().get_nodes_in_group("cake_nodes")
		
		if cake_nodes.size() > 0:
			cookie_space = randi() % cake_nodes.size()
			var cake_node = cake_nodes[cookie_space]
			cake_node.cake = true
			cake_node.get_node("Cake").visible = true
		
		
		new_game = false

# Reset game state, used for starting a new game
func reset_state():
	new_game = true
	cookie_space = 0
	current_board = ""
	player_turn = 1
	turn = 1
	
	current_minigame = null
	minigame_type = null
	minigame_teams = null
	minigame_duel_reward = null
	
	trap_states = []
	
	for p in players:
		p.cookies = 0
		p.cookies_gui = 0
		p.cakes = 0
		p.space = null

func new_savegame():
	current_savegame = SaveGameLoader.SaveGame.new()
	is_new_savegame = true

func save_game():
	var r_players = get_tree().get_nodes_in_group("players")
	var controller = get_tree().get_nodes_in_group("Controller")[0]
	
	current_savegame.board_path = current_board;
	for i in range(amount_of_players):
		current_savegame.players[i].player_name = r_players[i].player_name
		current_savegame.players[i].is_ai = r_players[i].is_ai
		current_savegame.players[i].space = r_players[i].space.get_path()
		current_savegame.players[i].character = players[i].character
		current_savegame.players[i].cookies = r_players[i].cookies
		current_savegame.players[i].cakes = r_players[i].cakes
		current_savegame.players[i].items = duplicate_items(r_players[i].items)
	
	current_savegame.cookie_space = cookie_space
	current_savegame.current_minigame = current_minigame
	current_savegame.player_turn = controller.player_turn
	current_savegame.award_type = award
	
	current_savegame.trap_states = []
	
	for trap in get_tree().get_nodes_in_group("trap"):
		var state = { node = trap.get_path(), item = inst2dict(trap.trap), player = trap.trap_player.get_path() }
		
		current_savegame.trap_states.push_back(state)
	
	savegame_loader.save(current_savegame)
