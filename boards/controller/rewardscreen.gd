extends Spatial

func _ready():
	for i in range(Global.amount_of_players):
		var player = get_node("Player" + var2str(i+1))
		var new_model = load(Global.character_loader.get_character_path(Global.players[i].character)).instance()
		new_model.name = player.name
		
		remove_child(player)
		add_child(new_model)
	
	var i = 0
	for player_id in Global.placement:
		i = i + 1
		var player = get_node("Player"+var2str(player_id));
		var node = get_node("Placement" + var2str(i) + "/Position")
		
		player.transform = node.global_transform
		if player.has_node("AnimationPlayer"):
			if i < 4:
				player.get_node("AnimationPlayer").play("happy")
			else:
				player.get_node("AnimationPlayer").play("sad")


func _on_Timer_timeout():
	Global.call_deferred("_goto_scene_ingame", Global.current_board)
