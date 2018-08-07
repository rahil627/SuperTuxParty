extends Node

class PlayerState:
	var player_id = 0;
	var player_name = "";
	var cookies = 0;
	var cakes = 0;
	var space = 1;

var current_scene = null;
var amount_of_players = 4;
var players = [PlayerState.new(), PlayerState.new(), PlayerState.new(), PlayerState.new()];
var max_turns = 20;
var load_previous_state = false;
var turn = 1;

func _ready():
	var root = get_tree().get_root();
	current_scene = root.get_child(root.get_child_count() -1);

func goto_scene(path):
	call_deferred("_goto_scene", path);

func _goto_scene(path):
	current_scene.free();
	
	var s = ResourceLoader.load(path);
	current_scene = s.instance();
	
	get_tree().get_root().add_child(current_scene);
	get_tree().set_current_scene(current_scene);

func goto_minigame():
	var r_players = get_tree().get_nodes_in_group("players");
		
	for i in range(r_players.size()):
		players[i].player_id = r_players[i].player_id;
		players[i].player_name = r_players[i].name;
		players[i].cookies = r_players[i].cookies;
		players[i].cakes = r_players[i].cakes;
		players[i].space = r_players[i].space;
	goto_scene("res://levels/minigames/knock_off/knock_off.tscn");

func goto_board(placement):
	for i in range(amount_of_players):
		players[placement[i] - 1].cookies += 15 - (i * 5);
	
	goto_scene("res://levels/board/board.tscn");

func load_board_state():
	if load_previous_state:
		var r_players = get_tree().get_nodes_in_group("players");
	
		for i in range(r_players.size()):
			r_players[i].player_id = players[i].player_id;
			r_players[i].name = players[i].player_name;
			r_players[i].cookies = players[i].cookies;
			r_players[i].cakes = players[i].cakes;
			r_players[i].space = players[i].space;
			r_players[i].translation = current_scene.get_node("Node" + var2str(r_players[i].space)).translation + Vector3(0, 1 + i, 0);
			if i == 0:
				current_scene.get_node("Controller").translation = r_players[i].translation;
	else:
		load_previous_state = true;