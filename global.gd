extends Node


# Information about a player that needs to be saved when a scene change occurs
class PlayerState:
	var player_id = 0
	var player_name = ""
	var character = ""
	var cookies = 0
	var cookies_gui = 0
	var cakes = 0
	
	# Which space on the board the player is standing on
	var space = null

var PluginSystem = preload("res://pluginsystem.gd")
var plugin_system = PluginSystem.new()

var BoardLoader = preload("res://boards/boardloader.gd")
var board_loader = BoardLoader.new()

var MinigameLoader = preload("res://minigames/minigameloader.gd")
var minigame_loader = MinigameLoader.new(self)

var CharacterLoader = preload("res://characters/characterloader.gd")
var character_loader = CharacterLoader.new()

# linear, 1st: 15, 2nd: 10, 3rd: 5, 4th: 0
# winner_only, 1st: 10, 2nd-4th: 0
enum AWARD_T {
	linear,
	winner_only
}


var amount_of_players = 4

# Option to choose how players are awarded after completing a mini-game
var award = AWARD_T.linear

# Resource location of the current board
var current_board

# Pointer to top-level node in current scene
var current_scene = null
var max_turns = 10

# Stops the controller from loading information when starting a new game
var new_game = true
var players = [PlayerState.new(), PlayerState.new(), PlayerState.new(), PlayerState.new()]
var turn = 1


func _ready():
	randomize()
	var root = get_tree().get_root()
	current_scene = root.get_child(root.get_child_count() -1)

func load_board(board, names, characters):
	for i in range(characters.size()):
		players[i].player_name = names[i]
		players[i].character = characters[i]
	current_board = board;
	call_deferred("_goto_scene_ingame", board)

# Goto a specific scene without saving player states
func goto_scene(path):
	call_deferred("_goto_scene", path)

# Internal function for actually changing scene without saving any game state
func _goto_scene(path):
	current_scene.free()
	
	var s = ResourceLoader.load(path)
	
	current_scene = s.instance()
	
	get_tree().get_root().add_child(current_scene)
	get_tree().set_current_scene(current_scene)

# Internal function for actually changing scene while handling player objects
func _goto_scene_ingame(path):
	current_scene.free()
	
	var s = ResourceLoader.load(path)
	
	current_scene = s.instance()
	
	for i in range(players.size()):
		var new_model = ResourceLoader.load(character_loader.get_character_path(players[i].character)).instance()
		new_model.get_children()[0].set_surface_material(0, ResourceLoader.load(character_loader.get_material_path(players[i].character)))
		new_model.set_name("Model")
		
		var old_model = current_scene.get_node("Player" + var2str(i+1) + "/Model")
		new_model.translation = old_model.translation
		new_model.translation = old_model.scale
		new_model.translation = old_model.rotation
		old_model.replace_by(new_model, true)
		
		if current_scene.has_node("Player" + var2str(i+1) + "/Shape"):
			var collision_shape = current_scene.get_node("Player" + var2str(i+1) + "/Shape")
			collision_shape.translation = new_model.translation
			collision_shape.translation.y += new_model.get_child(0).translation.y
			collision_shape.scale = new_model.scale
			collision_shape.rotation = new_model.rotation + Vector3(deg2rad(90), 0, 0)
			collision_shape.shape = ResourceLoader.load(character_loader.get_collision_shape_path(players[i].character))
	
	get_tree().get_root().add_child(current_scene)
	get_tree().set_current_scene(current_scene)
	

# Change scene to one of the mini-games
func goto_minigame(minigame = ""):
	
	# Current player nodes
	var r_players = get_tree().get_nodes_in_group("players")
	
	# Save player states in the array 'players'
	for i in range(r_players.size()):
		players[i].player_id = r_players[i].player_id
		players[i].player_name = r_players[i].player_name
		players[i].cookies = r_players[i].cookies
		players[i].cookies_gui = r_players[i].cookies_gui
		players[i].cakes = r_players[i].cakes
		players[i].space = r_players[i].space.get_path()
	
	if minigame == "":
		minigame_loader.goto_random_ffa()
	else:
		call_deferred("_goto_scene_ingame", minigame)

# Go back to board from mini-game, placement is an array with the players' id:s
func goto_board(placement):
	if award == AWARD_T.linear:
		for i in range(amount_of_players):
			players[placement[i] - 1].cookies += 15 - (i * 5)
		
	elif award == AWARD_T.winner_only:
		players[placement[0] - 1].cookies += 10
	
	call_deferred("_goto_scene_ingame", current_board)

func load_board_state():
	var r_players = get_tree().get_nodes_in_group("players") # Current player nodes
	
	if !new_game:
		
		# Load player states from the array 'players'
		for i in range(r_players.size()):
			r_players[i].player_id = players[i].player_id
			r_players[i].player_name = players[i].player_name
			r_players[i].cookies = players[i].cookies
			r_players[i].cookies_gui = players[i].cookies_gui
			r_players[i].cakes = players[i].cakes
			r_players[i].space = current_scene.get_node(players[i].space)
			
			# Move piece to the right space, increase y-axis so two players are not placed inside each other
			var controller = current_scene.get_node("Controller")
			var num = controller.get_players_on_space(r_players[i].space)
			var translation = controller.EMPTY_SPACE_PLAYER_TRANSLATION
			if num > 1:
				translation = controller.PLAYER_TRANSLATION[num - 1]
			r_players[i].translation = r_players[i].space.translation + translation
			
			if i == 0:
				current_scene.get_node("Controller").translation = r_players[i].translation # Move camera to player 1
	else:
		for i in range(r_players.size()):
			r_players[i].player_name = players[i].player_name
		
		new_game = false

# Reset game state, used for starting a new game
func reset_state():
	new_game = true
	current_board = ""
	players = [PlayerState.new(), PlayerState.new(), PlayerState.new(), PlayerState.new()]
	turn = 1