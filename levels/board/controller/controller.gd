extends Spatial

var players = null;
var player_turn = 1;
var nodes = null;

func _ready():
	randomize();
	nodes = get_tree().get_nodes_in_group("nodes");
	var i = 1;
	
	players = get_tree().get_nodes_in_group("players");
	for p in players:
		p.player_id = i;
		i += 1;
	
	$"/root/Global".load_board_state();
	
	if get_parent().has_node("Player" + var2str(player_turn)):
		var player = get_node("../Player" + var2str(player_turn));
		$Screen/PlayerInfo/Player.text = "Player " + var2str(player_turn) + "'s turn"
		$Screen/PlayerInfo/Turn.text = "Turn: " + var2str($"/root/Global".turn);
		$Screen/PlayerInfo/Cookies.text = "Cookies: " + var2str(player.cookies);
		$Screen/PlayerInfo/Cakes.text = "Cake: " + var2str(player.cakes);

func _on_Roll_pressed():
	if player_turn <= players.size():
		var dice = (randi() % 6) + 1;
		var player = players[player_turn - 1];
		
		if (player.space + dice - 1) < nodes.size():
			player.translation = nodes[player.space + dice - 1].translation + Vector3(0, 3, 0);
			self.translation = player.translation - Vector3(0, 3, 0);
			$Screen/Panel/Dice.text = "Rolled: " + var2str(dice);
			player.space += dice;
		else:
			var space = (player.space + dice) - nodes.size();
			player.translation = nodes[space].translation + Vector3(0, 3, 0);
			self.translation = player.translation - Vector3(0, 3, 0);
			$Screen/Panel/Dice.text = "Rolled: " + var2str(dice);
			player.space = space;
		
		$Screen/PlayerInfo/Player.text = "Player " + var2str(player_turn) + "'s turn"
		$Screen/PlayerInfo/Turn.text = "Turn: " + var2str($"/root/Global".turn);
		$Screen/PlayerInfo/Cookies.text = "Cookies: " + var2str(player.cookies);
		$Screen/PlayerInfo/Cakes.text = "Cake: " + var2str(player.cakes);
	else:
		player_turn = 1;
		
		$"/root/Global".turn += 1;
		$"/root/Global".goto_minigame();
	player_turn += 1;