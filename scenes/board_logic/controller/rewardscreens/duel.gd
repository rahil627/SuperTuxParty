extends Spatial

func _ready() -> void:
	var i := 0
	for p in Global.placement:
		for player_id in p:
			i += 1
			var new_model = load(Global.character_loader.get_character_path(
					Global.players[player_id - 1].character)).instance()
			new_model.name = "Player" + str(i)

			var player = get_node("Player" + str(i))
			new_model.transform = player.global_transform
			if i == 1 and len(Global.placement) == 2:
				new_model.get_node("AnimationPlayer").play("happy")
			else:
				new_model.get_node("AnimationPlayer").play("sad")

			player.replace_by(new_model)

func _on_Timer_timeout() -> void:
	Global.minigame_type = -1
	Global.minigame_teams = []
	Global.minigame_duel_reward = -1
	Global._goto_scene_board()
