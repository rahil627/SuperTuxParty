extends Spatial

func _ready():
	for i in range(Global.amount_of_players):
		var character = Global.players[i].character
		var new_model = PluginSystem.character_loader.load_character(character)
		new_model.name = "Player" + var2str(i+1)
		
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
