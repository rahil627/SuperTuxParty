extends Spatial

var player_turn = 1;

func _on_Roll_pressed():
	if get_parent().has_node("Player" + var2str(player_turn)):
		var dice = (randi() % 6) + 1;
		var player = get_node("../Player" + var2str(player_turn));
		
		if get_parent().has_node("Node" + var2str(player.space + dice)):
			player.translation = get_node("../Node" + var2str(player.space + dice)).translation + Vector3(0, 3, 0);
			self.translation = get_node("../Node" + var2str(player.space + dice)).translation;
			$Screen/Dice.text = var2str(dice);
			player.space += dice;
		else:
			$Screen/Dice.text = "Tux Wins!"
		
		player_turn += 1;
	else:
		player_turn = 1;
		get_tree().change_scene("res://levels/knock_off.tscn");
