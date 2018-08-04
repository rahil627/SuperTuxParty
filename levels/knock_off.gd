extends Spatial

var losses = 0;
var placement = [0, 0, 0, 0];

func _ready():
	var i = 1;
	
	for p in get_tree().get_nodes_in_group("Players"):
		p.player_id = i;
		i += 1;

func _process(delta):
	var players = get_tree().get_nodes_in_group("Players");
	for p in players:
		if p.translation.y < -10:
			losses += 1;
			placement[4 - losses] = p.player_id;
			p.queue_free();
	
	if players.size() == 1:
		placement[0] = players[0].player_id;
		
		print(placement);
		
		get_tree().change_scene("res://levels/board/board.tscn");