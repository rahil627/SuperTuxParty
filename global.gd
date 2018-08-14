extends Node

# Information about a player that needs to be saved when a scene change occurs
class PlayerState:
	var player_id = 0 # Used to identify the player
	var player_name = ""
	var cookies = 0
	var cakes = 0
	var space = 1 # Which space on the board the player is standing on

var MinigameLoader = preload("res://minigames/minigameloader.gd")
var minigame_loader

# linear, 1st: 15, 2nd: 10, 3rd: 5, 4th: 0
# winner_only, 1st: 10, 2nd-4th: 0
enum AWARD_T {
	linear,
	winner_only
}

var award = AWARD_T.linear # Option to choose how players are awarded after completing a mini-game
var current_board # Resource location of the current board
var current_scene = null # Pointer to top-level node in current scene
var amount_of_players = 4
var players = [PlayerState.new(), PlayerState.new(), PlayerState.new(), PlayerState.new()]
var max_turns = 10
var new_game = true # Stops the controller from loading information when starting a new game
var turn = 1

func _ready():
	var root = get_tree().get_root()
	current_scene = root.get_child(root.get_child_count() -1)
	minigame_loader =  MinigameLoader.new(self)

func load_board(board):
	current_board = board;
	goto_scene(board)

func goto_scene(path):
	call_deferred("_goto_scene", path)

# Internal function for actually changing scene, should not be used directly: see goto_scene(path)
func _goto_scene(path):
	current_scene.free()
	
	var s = ResourceLoader.load(path)
	current_scene = s.instance()
	
	get_tree().get_root().add_child(current_scene)
	get_tree().set_current_scene(current_scene)

# Change scene to one of the mini-games
func goto_minigame():
	var r_players = get_tree().get_nodes_in_group("players") # Current player nodes
	
	# Save player states in the array 'players'
	for i in range(r_players.size()):
		players[i].player_id = r_players[i].player_id
		players[i].player_name = r_players[i].player_name
		players[i].cookies = r_players[i].cookies
		players[i].cakes = r_players[i].cakes
		players[i].space = r_players[i].space
	minigame_loader.goto_random_ffa()
	
# Go back to board from mini-game, placement is an array with the players' id:s
func goto_board(placement):
	if award == AWARD_T.linear:
		for i in range(amount_of_players):
			players[placement[i] - 1].cookies += 15 - (i * 5)
		
	elif award == AWARD_T.winner_only:
		players[placement[0] - 1].cookies += 10
	
	goto_scene(current_board)

func load_board_state():
	if !new_game:
		var r_players = get_tree().get_nodes_in_group("players") # Current player nodes
		
		# Load player states from the array 'players'
		for i in range(r_players.size()):
			r_players[i].player_id = players[i].player_id
			r_players[i].player_name = players[i].player_name
			r_players[i].cookies = players[i].cookies
			r_players[i].cakes = players[i].cakes
			r_players[i].space = players[i].space
			
			# Move piece to the right space, increase y-axis so two players are not placed inside each other
			var controller = current_scene.get_node("Controller")
			var num = controller.get_players_on_space(r_players[i].space)
			var translation = controller.EMPTY_SPACE_PLAYER_TRANSLATION
			if num > 1:
				translation = controller.PLAYER_TRANSLATION[num - 1]
			r_players[i].translation = current_scene.get_node("Node" + var2str(r_players[i].space)).translation + translation
			
			if i == 0:
				current_scene.get_node("Controller").translation = r_players[i].translation # Move camera to player 1
	else:
		new_game = false