extends Node

# Information about a player that needs to be saved when a scene change occurs.
class PlayerState:
	var player_id := 0
	var player_name := ""
	var is_ai := false
	var ai_difficulty: int = Difficulty.NORMAL
	var character := ""
	var cookies := 0
	var cookies_gui := 0
	var cakes := 0
	var items := []

	# Which space on the board the player is standing on.
	var space

class BoardOverrides:
	var cake_cost: int
	var max_turns: int
	var ai_difficulty: int
	# Option to choose how players are awarded after completing a mini-game.
	var award: int = AWARD_TYPE.LINEAR

const MINIGAME_REWARD_SCREEN_PATH_FFA =\
		"res://scenes/board_logic/controller/rewardscreens/ffa.tscn"
const MINIGAME_REWARD_SCREEN_PATH_DUEL =\
		"res://scenes/board_logic/controller/rewardscreens/duel.tscn"
const MINIGAME_REWARD_SCREEN_PATH_1V3 =\
		"res://scenes/board_logic/controller/rewardscreens/1v3.tscn"
const MINIGAME_REWARD_SCREEN_PATH_2V2 =\
		"res://scenes/board_logic/controller/rewardscreens/2v2.tscn"

const LOADING_SCREEN = preload("res://scenes/menus/loading_screen.tscn")

const MINIGAME_TEAM_COLORS = [Color(1, 0, 0), Color(0, 0, 1)]

var plugin_system: Object = preload("res://scripts/plugin_system.gd").new()

var board_loader: Object = preload("res://scripts/board_loader.gd").new()
var minigame_loader: Object = preload("res://scripts/minigame_loader.gd").new()
var character_loader: Object =\
		preload("res://scripts/character_loader.gd").new()
var item_loader: Object = preload("res://scripts/item_loader.gd").new()

var savegame_loader := SaveGameLoader.new()

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
	FREE_FOR_ALL,
	NOLOK,
	GNU
}

enum Difficulty {
	EASY,
	NORMAL,
	HARD
}

signal language_changed

var joypad_display: int = JOYPAD_DISPLAY_TYPE.NUMBERS

var amount_of_players := 4

# Is true if you exit to menu from inside the game.
var quit_to_menu := false

# Pause game if the window loses focus.
var pause_window_unfocus := true

# Mute game if the window loses focus.
var mute_window_unfocus := true
var _was_muted := false

var overrides: BoardOverrides = BoardOverrides.new()

# Resource location of the current board.
var current_board: String

# Pointer to top-level node in current scene.
var current_scene: Node

# Stops the controller from loading information when starting a new game.
var new_game := true
var cake_space := NodePath()
var players := [PlayerState.new(), PlayerState.new(), PlayerState.new(),
		PlayerState.new()]
var turn := 1
var player_turn := 1

# Stores where a trap is placed and what item and player created it.
var trap_states := []

# The minigame to return to in "try minigame" mode.
# If it is null, then no minigame is tried and the next turn resumes.
var current_minigame: Object
var minigame_type: int
var minigame_teams: Array

var minigame_duel_reward: int

var current_savegame: Object
var is_new_savegame := false

# Stores the last placement (not changed when you press "try").
# Used in rewardscreen.gd.
var placement

var _board_loaded_translations := []
var _minigame_loaded_translations := []

var interactive_loaders := []
var loaded_scene := null

func _ready() -> void:
	randomize()
	var root: Viewport = get_tree().get_root()
	current_scene = root.get_child(root.get_child_count() - 1)

	savegame_loader.read_savegames()

func _notification(what: int) -> void:
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

func _process(_delta: float):
	var filtered = []
	for data in interactive_loaders:
		var err = data[0].poll()
		match err:
			OK:
				filtered.append(data)
			ERR_FILE_EOF:
				data[1].call(data[2], data[0].get_resource(), data[4])
			_:
				push_error("Failed to load resource: %s" % data[3])
	interactive_loaders = filtered

func get_loader_progress():
	var loaded = 0
	var stages = 0
	for data in interactive_loaders:
		loaded += data[0].get_stage()
		stages += data[0].get_stage_count()
	return [loaded, stages]

func _load_interactive(path: String, base: Object, method: String, arg):
	interactive_loaders.append([ResourceLoader.load_interactive(path), base, method, path, arg])

func load_board(board: String, names: Array, characters: Array,
		human_players: int) -> void:
	var dir = Directory.new()
	dir.open(board.get_base_dir() + "/translations")
	dir.list_dir_begin(true)
	while true:
		var file_name = dir.get_next()
		if file_name == "":
			break

		if file_name.ends_with(".translation") or file_name.ends_with(".po"):
			_load_interactive(dir.get_current_dir() + "/" + file_name, self, "_install_translation_board", file_name)

	dir.list_dir_end()

	for i in characters.size():
		players[i].player_name = names[i]
		players[i].character = characters[i]
		if i >= human_players:
			players[i].is_ai = true
			players[i].ai_difficulty = overrides.ai_difficulty
	current_board = board
	call_deferred("_goto_scene_ingame", board)

func _install_translation_board(translation, file_name: String):
	if not translation is Translation:
		push_warning("Error: file " + file_name + " is not a valid translation")
		return

	TranslationServer.add_translation(translation)
	_board_loaded_translations.push_back(translation)

func _install_translation_minigame(translation, file_name: String):
	if not translation is Translation:
		push_warning("Error: file " + file_name + " is not a valid translation")
		return

	TranslationServer.add_translation(translation)
	_minigame_loaded_translations.push_back(translation)

func change_scene():
	current_scene.free()
	current_scene = loaded_scene
	loaded_scene = null

	get_tree().get_root().add_child(current_scene)
	get_tree().set_current_scene(current_scene)

# Goto a specific scene without saving player states.
func goto_scene(path: String) -> void:
	call_deferred("_goto_scene", path)

# Internal function for actually changing scene without saving any game state.
func _goto_scene(path: String) -> void:
	current_scene.queue_free()
	current_scene = LOADING_SCREEN.instance()
	
	get_tree().get_root().add_child(current_scene)
	get_tree().set_current_scene(current_scene)
	_load_interactive(path, self, "_goto_scene_callback", null)

func _goto_scene_callback(s: PackedScene, _arg):
	loaded_scene = s.instance()

# Internal function for actually changing scene while handling player objects.
func _goto_scene_ingame(path: String, instance_pause_menu := false) -> void:
	current_scene.queue_free()
	current_scene = LOADING_SCREEN.instance()

	get_tree().get_root().add_child(current_scene)
	get_tree().set_current_scene(current_scene)
	_load_interactive(path, self, "_goto_scene_ingame_callback", instance_pause_menu)

func _goto_scene_ingame_callback(s: PackedScene, instance_pause_menu: bool):
	loaded_scene = s.instance()

	if instance_pause_menu:
		loaded_scene.add_child(
				preload("res://scenes/menus/pause_menu.tscn").instance())

	if not minigame_teams:
		for i in players.size():
			var player = loaded_scene.get_node("Player" + str(i + 1))

			var new_model = load(character_loader.get_character_path(
					players[i].character)).instance()
			new_model.set_name("Model")

			var old_model = player.get_node("Model")
			new_model.translation = old_model.translation
			new_model.scale = old_model.scale
			new_model.rotation = old_model.rotation
			old_model.replace_by(new_model, true)

			player.is_ai = players[i].is_ai
			
			if "ai_difficulty" in player:
				player.ai_difficulty = players[i].ai_difficulty

			if player.has_node("Shape"):
				var collision_shape = player.get_node("Shape")
				collision_shape.translation += new_model.translation
				collision_shape.shape = load(
						character_loader.get_collision_shape_path(
						players[i].character))
	else:
		var i := 1
		for team_id in minigame_teams.size():
			var team = minigame_teams[team_id]
			for player_id in team:
				var player = loaded_scene.get_node("Player" + str(i))

				var new_model =\
						load(character_loader.get_character_path(
						players[player_id - 1].character)).instance()
				new_model.set_name("Model")

				var old_model = player.get_node("Model")
				new_model.translation = old_model.translation
				new_model.scale = old_model.scale
				new_model.rotation = old_model.rotation
				old_model.replace_by(new_model, true)

				player.is_ai = players[player_id - 1].is_ai
				if "ai_difficulty" in player:
					player.ai_difficulty = players[player_id - 1].ai_difficulty
				player.player_id = player_id

				var shape: Shape =\
						load(character_loader.get_collision_shape_path(
						players[player_id - 1].character))
				if minigame_type == MINIGAME_TYPES.TWO_VS_TWO:
					var bbox : AABB = Utility.get_aabb_from_shape(shape)

					var indicator = preload(\
							"res://scenes/team_indicator/team_indicator.tscn"\
							).instance()
					indicator.material_override.albedo_color =\
							MINIGAME_TEAM_COLORS[team_id]
					indicator.translation.y = bbox.size.y + 0.05
					new_model.add_child(indicator)

				if player.has_node("Shape"):
					var collision_shape = player.get_node("Shape")
					collision_shape.translation += new_model.translation
					collision_shape.shape = shape

				i += 1

		# Remove unnecessary players.
		while i <= Global.amount_of_players:
			var player = loaded_scene.get_node("Player" + str(i))
			loaded_scene.remove_child(player)
			player.queue_free()
			i += 1

func load_board_from_savegame(savegame) -> void:
	current_savegame = savegame
	is_new_savegame = false
	new_game = false

	var dir := Directory.new()
	dir.open(savegame.board_path.get_base_dir() + "/translations")
	dir.list_dir_begin(true)
	while true:
		var file_name: String = dir.get_next()
		if file_name == "":
			break

		if file_name.ends_with(".translation") or file_name.ends_with(".po"):
			_load_interactive(dir.get_current_dir() + "/" + file_name, self, "_install_translation_board", file_name)

	dir.list_dir_end()

	current_board = savegame.board_path
	for i in amount_of_players:
		players[i].player_id = i + 1
		players[i].player_name = savegame.players[i].player_name
		players[i].is_ai = savegame.players[i].is_ai
		players[i].ai_difficulty = int(savegame.players[i].ai_difficulty)
		players[i].space = savegame.players[i].space
		players[i].character = savegame.players[i].character
		players[i].cookies = int(savegame.players[i].cookies)
		players[i].cakes = int(savegame.players[i].cakes)
		players[i].items = savegame.players[i].items

	cake_space = savegame.cake_space
	if savegame.current_minigame:
		current_minigame = minigame_loader.parse_file(savegame.current_minigame)
	else:
		current_minigame = null
	minigame_type = int(savegame.minigame_type)
	minigame_teams = savegame.minigame_teams
	for team in minigame_teams:
		for i in range(len(team)):
			team[i] = int(team[i])
	player_turn = int(current_savegame.player_turn)
	turn = int(current_savegame.turn)
	overrides.cake_cost = int(savegame.cake_cost)
	overrides.max_turns = int(savegame.max_turns)
	overrides.award = int(savegame.award_type)

	trap_states = savegame.trap_states.duplicate()

	call_deferred("_goto_scene_ingame", current_board)

# Change scene to one of the mini-games.
func goto_minigame(minigame, try := false) -> void:
	var dir := Directory.new()
	dir.open(minigame.translation_directory)
	dir.list_dir_begin(true)
	while true:
		var file_name: String = dir.get_next()
		if file_name == "":
			break

		if file_name.ends_with(".translation") or file_name.ends_with(".po"):
			_load_interactive(dir.get_current_dir() + "/" + file_name, self, "_install_translation_minigame", file_name)

	dir.list_dir_end()

	# Current player nodes.
	var r_players = get_tree().get_nodes_in_group("players")
	if not try:
		current_minigame = null

	player_turn = get_tree().get_nodes_in_group("Controller")[0].player_turn

	trap_states.clear()
	for trap in get_tree().get_nodes_in_group("trap"):
		var state := {
			node = trap.get_path(),
			item = trap.trap,
			player = trap.trap_player.get_path()
		}

		trap_states.push_back(state)

	# Save player states in the array 'players'.
	for i in r_players.size():
		players[i].player_id = r_players[i].player_id
		players[i].player_name = r_players[i].player_name
		players[i].cookies = r_players[i].cookies
		players[i].cookies_gui = r_players[i].cookies_gui
		players[i].cakes = r_players[i].cakes
		players[i].space = r_players[i].space.get_path()

		players[i].items = duplicate_items(r_players[i].items)

	call_deferred("_goto_scene_ingame", minigame.scene_path, true)

func duplicate_items(items: Array) -> Array:
	var list := []
	for item in items:
		list.push_back(inst2dict(item))

	return list

func deduplicate_items(items: Array) -> Array:
	var list := []
	for item in items:
		var deserialized = dict2inst(item)
		deserialized.type = int(deserialized.type)
		list.push_back(deserialized)

	return list

# Go back to board from mini-game, placement is an array with the players' ids.
func _goto_board(new_placement) -> void:
	for t in _minigame_loaded_translations:
		TranslationServer.remove_translation(t)
	_minigame_loaded_translations.clear()

	# Only award if it's not a test.
	if current_minigame != null:
		call_deferred("_goto_scene_ingame", current_board)
		return

	placement = new_placement
	match minigame_type:
		MINIGAME_TYPES.FREE_FOR_ALL:
			match overrides.award:
				AWARD_TYPE.LINEAR:
					# Store the current place.
					var place = 0
					for i in placement.size():
						for j in placement[i].size():
							players[placement[i][j] - 1].cookies +=\
									15 - place*5
						# If placement looks like this: [[1, 2], [3], [4]].
						# Then the placement is 1, 2 are 1st, 3 is 3rd,
						# 4 is 4th. Therefore we need to increase the place by
						# the amount of players on that place.
						place += placement[i].size()
				AWARD_TYPE.WINNER_ONLY:
					for p in placement[0]:
						players[p - 1].cookies += 10

			call_deferred("_goto_scene", MINIGAME_REWARD_SCREEN_PATH_FFA)
		MINIGAME_TYPES.TWO_VS_TWO:
			if placement != -1:
				for player_id in minigame_teams[placement]:
					players[player_id - 1].cookies += 10

			call_deferred("_goto_scene", MINIGAME_REWARD_SCREEN_PATH_2V2)
		MINIGAME_TYPES.ONE_VS_THREE:
			if placement != -1:
				for player_id in minigame_teams[placement]:
					# Has the solo player won?
					if placement == 1:
						players[player_id - 1].cookies += 10
					else:
						players[player_id - 1].cookies += 5

			call_deferred("_goto_scene", MINIGAME_REWARD_SCREEN_PATH_1V3)
		MINIGAME_TYPES.DUEL:
			if len(placement) == 2:
				match minigame_duel_reward:
					MINIGAME_DUEL_REWARDS.TEN_COOKIES:
						var other_player_cookies := int(
								min(players[placement[1][0] - 1].cookies, 10))
						players[placement[0][0] - 1].cookies +=\
								other_player_cookies
						players[placement[1][0] - 1].cookies -=\
								other_player_cookies
					MINIGAME_DUEL_REWARDS.ONE_CAKE:
						var other_player_cakes := int(
								min(players[placement[1][0] - 1].cakes, 1))
						players[placement[0][0] - 1].cakes +=\
								other_player_cakes
						players[placement[1][0] - 1].cakes -=\
								other_player_cakes

			call_deferred("_goto_scene", MINIGAME_REWARD_SCREEN_PATH_DUEL)
		MINIGAME_TYPES.NOLOK:
			# TODO: Reward

			# TODO: Rewardscreen
			call_deferred("_goto_scene_ingame", current_board)
		MINIGAME_TYPES.GNU:
			# TODO: Better reward
			if placement:
				for player in players:
					player.cookies += 10

			# TODO: Reward screen
			call_deferred("_goto_scene_ingame", current_board)

func minigame_win_by_points(points: Array) -> void:
	var players := []
	var p := []

	# Sort into the array players while grouping players with the same amount
	# of points together.
	for i in points.size():
		var insert_index: int = p.bsearch(points[i])
		# Does the current entry differ (if it's not out of range).
		# If yes we need to insert a new entry.
		if insert_index == p.size() or p[insert_index] != points[i]:
			p.insert(insert_index, points[i])
			if minigame_type == MINIGAME_TYPES.FREE_FOR_ALL:
				players.insert(insert_index, [minigame_teams[0][i]])
			else:
				players.insert(insert_index, [minigame_teams[i][0]])
		else:
			if minigame_type == MINIGAME_TYPES.FREE_FOR_ALL:
				players[insert_index].append(minigame_teams[0][i])
			else:
				players[insert_index].append(minigame_teams[i][0])

	# We need to sort from high to low.
	players.invert()
	_goto_board(players)

func minigame_win_by_position(players: Array) -> void:
	var placement := []

	# We're expecting an array with multiple possible players per placement in
	# _goto_board.
	for p in players:
		placement.append([p])

	_goto_board(placement)

func minigame_duel_draw() -> void:
	_goto_board([[minigame_teams[0][0], minigame_teams[1][0]]])

func minigame_team_win(team) -> void:
	_goto_board(team)

func minigame_team_win_by_points(points: Array) -> void:
	if points[0] == points[1]:
		_goto_board(-1)
	elif points[0] > points[1]:
		_goto_board(0)
	else:
		_goto_board(1)

func minigame_team_win_by_player(player) -> void:
	for i in minigame_teams.size():
		if minigame_teams[i].has(player):
			_goto_board(i)

			return

func minigame_team_draw() -> void:
	_goto_board(-1)

func minigame_1v3_draw() -> void:
	_goto_board(-1)

func minigame_1v3_win_team_players() -> void:
	_goto_board(0)

func minigame_1v3_win_solo_player() -> void:
	_goto_board(1)

func minigame_nolok_win() -> void:
	_goto_board(true)

func minigame_nolok_loose() -> void:
	_goto_board(false)

func minigame_gnu_win() -> void:
	_goto_board(true)

func minigame_gnu_loose() -> void:
	_goto_board(false)

func load_board_state(controller: Spatial) -> void:
	controller.COOKIES_FOR_CAKE = overrides.cake_cost
	controller.MAX_TURNS = overrides.max_turns

	# Current player nodes.
	var r_players: Array = get_tree().get_nodes_in_group("players")

	if not new_game:
		# Place cake spot back on the board.
		var cake_node: Spatial = controller.get_node(cake_space)
		cake_node.cake = true

		if current_minigame != null:
			controller.show_minigame_info(current_minigame)

		controller.player_turn = player_turn

		# Replace traps.
		for trap in trap_states:
			var node = get_node(trap.node)
			node.trap = trap.item
			node.trap_player = get_node(trap.player)

		# Load player states from the array 'players'.
		for i in range(r_players.size()):
			r_players[i].player_id = players[i].player_id
			r_players[i].player_name = players[i].player_name
			r_players[i].cookies = players[i].cookies
			r_players[i].cookies_gui = players[i].cookies_gui
			r_players[i].cakes = players[i].cakes
			r_players[i].space = current_scene.get_node(players[i].space)
			r_players[i].is_ai = players[i].is_ai
			r_players[i].ai_difficulty = players[i].ai_difficulty

			r_players[i].items = deduplicate_items(players[i].items)

			for item in r_players[i].items:
				# Load missing icons, material, etc.
				item.recreate_state()

			# Move piece to the right space, place them to different position
			# on the same space.
			var num: int = controller.get_players_on_space(r_players[i].space)
			var translation = controller.EMPTY_SPACE_PLAYER_TRANSLATION

			# Fix first player sitting in the middle of the space.
			if num == 2:
				for x in range(i):
					if r_players[i].space == r_players[x].space:
						r_players[x].translation =\
								r_players[x].space.translation +\
								controller.PLAYER_TRANSLATION[0]

			if num > 1:
				translation = controller.PLAYER_TRANSLATION[num - 1]
			r_players[i].translation =\
					r_players[i].space.translation + translation

			if i == controller.player_turn:
				# Move camera to player 1.
				controller.translation = r_players[i].translation
	else:
		for i in r_players.size():
			r_players[i].player_name = players[i].player_name
			r_players[i].is_ai = players[i].is_ai
			r_players[i].ai_difficulty = players[i].ai_difficulty

		new_game = false

# Reset game state, used for starting a new game.
func reset_state() -> void:
	new_game = true
	cake_space = NodePath()
	current_board = ""
	player_turn = 1
	turn = 1

	current_minigame = null
	minigame_type = -1
	minigame_teams = []
	minigame_duel_reward = -1

	trap_states = []

	for t in _minigame_loaded_translations:
		TranslationServer.remove_translation(t)
	_minigame_loaded_translations.clear()

	for t in _board_loaded_translations:
		TranslationServer.remove_translation(t)
	_board_loaded_translations.clear()

	for p in players:
		p.cookies = 0
		p.cookies_gui = 0
		p.cakes = 0
		p.space = null

func new_savegame() -> void:
	current_savegame = SaveGameLoader.SaveGame.new()
	is_new_savegame = true

func save_game() -> void:
	var r_players: Array = get_tree().get_nodes_in_group("players")
	var controller: Spatial = get_tree().get_nodes_in_group("Controller")[0]

	current_savegame.board_path = current_board;
	for i in amount_of_players:
		current_savegame.players[i].player_name = r_players[i].player_name
		current_savegame.players[i].is_ai = r_players[i].is_ai
		current_savegame.players[i].ai_difficulty = r_players[i].ai_difficulty
		current_savegame.players[i].space = r_players[i].space.get_path()
		current_savegame.players[i].character = players[i].character
		current_savegame.players[i].cookies = r_players[i].cookies
		current_savegame.players[i].cakes = r_players[i].cakes
		current_savegame.players[i].items = duplicate_items(r_players[i].items)

	current_savegame.cake_space = cake_space
	if current_minigame:
		current_savegame.current_minigame = current_minigame.file
	else:
		current_savegame.current_minigame = null
	current_savegame.minigame_type = minigame_type
	current_savegame.minigame_teams = minigame_teams.duplicate()
	current_savegame.player_turn = controller.player_turn
	current_savegame.turn = turn
	current_savegame.cake_cost = overrides.cake_cost
	current_savegame.max_turns = overrides.max_turns
	current_savegame.award_type = overrides.award

	current_savegame.trap_states = []

	for trap in get_tree().get_nodes_in_group("trap"):
		var state := {
			node = trap.get_path(),
			item = inst2dict(trap.trap),
			player = trap.trap_player.get_path()
		}

		current_savegame.trap_states.push_back(state)

	savegame_loader.save(current_savegame)
