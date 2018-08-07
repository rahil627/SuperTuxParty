extends Spatial

var players = null; # Array containing the player nodes
var player_turn = 1; # Keeps track of whose turn it is
var nodes = null; # Array containing the node nodes

func _ready():
	randomize();
	nodes = get_tree().get_nodes_in_group("nodes");
	
	# Give each player a unique id
	var i = 1;
	
	players = get_tree().get_nodes_in_group("players");
	for p in players:
		p.player_id = i;
		i += 1;
	
	$"/root/Global".load_board_state();
	
	# Initialize GUI
	if get_parent().has_node("Player" + var2str(player_turn)):
		var player = get_node("../Player" + var2str(player_turn));
		$Screen/PlayerInfo/Player.text = "Player " + var2str(player_turn) + "'s turn"
		$Screen/PlayerInfo/Turn.text = "Turn: " + var2str($"/root/Global".turn);
		$Screen/PlayerInfo/Cookies.text = "Cookies: " + var2str(player.cookies);
		$Screen/PlayerInfo/Cakes.text = "Cake: " + var2str(player.cakes);

func _on_Roll_pressed():
	if player_turn <= players.size():
		var dice = (randi() % 6) + 1; # Random number between 1 & 6
		var player = players[player_turn - 1];
		
		# If the player will exceed the number of spaces on the board then loop
		if (player.space + dice) <= nodes.size():
			player.translation = nodes[player.space + dice - 1].translation + Vector3(0, 3, 0);
			self.translation = player.translation - Vector3(0, 3, 0);
			player.space += dice; # Keep track of which space the player is standing on
		else:
			var space = (player.space + dice) - nodes.size();
			player.translation = nodes[space].translation + Vector3(0, 3, 0);
			self.translation = player.translation - Vector3(0, 3, 0);
			player.space = space; # Keep track of which space the player is standing on
		
		$Screen/Panel/Dice.text = "Rolled: " + var2str(dice); # Show which number was rolled
		
		
		# Update GUI for the next player
		$Screen/PlayerInfo/Player.text = "Player " + var2str(player_turn) + "'s turn"
		$Screen/PlayerInfo/Turn.text = "Turn: " + var2str($"/root/Global".turn);
		$Screen/PlayerInfo/Cookies.text = "Cookies: " + var2str(player.cookies);
		$Screen/PlayerInfo/Cakes.text = "Cake: " + var2str(player.cakes);
	else:
		# All players have had their turn, goto mini-game
		$"/root/Global".turn += 1;
		$"/root/Global".goto_minigame();
	player_turn += 1;