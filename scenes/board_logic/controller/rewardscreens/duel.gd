extends Spatial

func _ready() -> void:
	var i := 0
	for p in Global.minigame_summary.placement:
		for player_id in p:
			i += 1
			var character = Global.players[player_id - 1].character
			var new_model = PluginSystem.character_loader.load_character(character)
			new_model.name = "Player" + str(i)

			var player = get_node("Player" + str(i))
			new_model.transform = player.global_transform
			if i == 1 and len(Global.minigame_summary.placement) == 2:
				new_model.play_animation("happy")
			else:
				new_model.play_animation("sad")

			player.replace_by(new_model)

func _on_Timer_timeout() -> void:
	Global._goto_scene_board()
