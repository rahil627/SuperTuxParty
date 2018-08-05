extends Spatial

var player_turn = 1;
var turn = 1;

func _ready():
	if get_parent().has_node("Player" + var2str(player_turn)):
		var player = get_node("../Player" + var2str(player_turn));
		$Screen/PlayerInfo/Player.text = "Player " + var2str(player_turn) + "'s turn"
		$Screen/PlayerInfo/Turn.text = "Turn: " + var2str(turn);
		$Screen/PlayerInfo/Cookies.text = "Cookies: " + var2str(player.cookies);
		$Screen/PlayerInfo/Cakes.text = "Cakes: " + var2str(player.cakes);

func _on_Roll_pressed():
	if get_parent().has_node("Player" + var2str(player_turn)):
		var dice = (randi() % 6) + 1;
		var player = get_node("../Player" + var2str(player_turn));
		
		if get_parent().has_node("Node" + var2str(player.space + dice)):
			player.translation = get_node("../Node" + var2str(player.space + dice)).translation + Vector3(0, 3, 0);
			self.translation = get_node("../Node" + var2str(player.space + dice)).translation;
			$Screen/Panel/Dice.text = "Rolled: " + var2str(dice);
			player.space += dice;
		else:
			$Screen/Dice.text = "Tux Wins!"
		
		$Screen/PlayerInfo/Player.text = "Player " + var2str(player_turn) + "'s turn"
		$Screen/PlayerInfo/Turn.text = "Turn: " + var2str(turn);
		$Screen/PlayerInfo/Cookies.text = "Cookies: " + var2str(player.cookies);
		$Screen/PlayerInfo/Cakes.text = "Cake: " + var2str(player.cakes);
	else:
		player_turn = 1;
		turn += 1;
		get_tree().change_scene("res://levels/knock_off/knock_off.tscn");
	player_turn += 1;