extends Spatial

func _ready():
	var i = 0
	for player_id in Global.placement:
		i += 1
		var new_model = load(Global.character_loader.get_character_path(Global.players[player_id - 1].character)).instance()
		new_model.name = "Player" + var2str(i)
		
		var player = get_node("Player"+var2str(i));
		new_model.transform = player.global_transform
		if i == 1:
			new_model.get_node("AnimationPlayer").play("happy")
		else:
			new_model.get_node("AnimationPlayer").play("sad")
		
		player.replace_by(new_model)

func _on_Timer_timeout():
	Global.minigame_type = null
	Global.minigame_teams = null
	Global.minigame_duel_reward = null
	Global.call_deferred("_goto_scene_ingame", Global.current_board)
