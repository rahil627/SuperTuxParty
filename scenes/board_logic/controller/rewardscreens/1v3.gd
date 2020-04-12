extends Spatial

func _ready():
	var i = 1
	for p_id in Global.minigame_summary.minigame_teams[0]:
		var node = get_node("Player"+var2str(i))
		var character = Global.players[p_id - 1].character
		var new_model = Global.character_loader.load_character(character)
		new_model.name = "Player" + var2str(i+1)

		new_model.transform = node.global_transform
		node.replace_by(new_model)

		if Global.minigame_summary.placement == 0:
			new_model.get_node("AnimationPlayer").play("happy")
		else:
			new_model.get_node("AnimationPlayer").play("sad")
		i += 1

	for p_id in Global.minigame_summary.minigame_teams[1]:
		var node = get_node("Player"+var2str(i))
		var character = Global.players[p_id - 1].character
		var new_model = Global.character_loader.load_character(character)
		new_model.name = "Player" + var2str(i+1)

		new_model.transform = node.global_transform
		node.replace_by(new_model)

		if Global.minigame_summary.placement == 1:
			new_model.get_node("AnimationPlayer").play("happy")
		else:
			new_model.get_node("AnimationPlayer").play("sad")
		i += 1

func _on_Timer_timeout():
	Global._goto_scene_board()
