extends Spatial

func _ready():
	var i = 1
	var placement = 0
	if Global.placement > 0:
		placement = Global.placement
	# Winning team
	for p_id in Global.minigame_teams[placement]:
		var node = get_node("Player" + var2str(i))
		var new_model = load(Global.character_loader.get_character_path(Global.players[p_id - 1].character)).instance()
		new_model.name = "Player" + var2str(i + 1)

		new_model.transform = node.global_transform
		node.replace_by(new_model)

		if Global.placement != -1:
			new_model.get_node("AnimationPlayer").play("happy")
		else:
			new_model.get_node("AnimationPlayer").play("sad")
		i += 1

	# Loosing team
	for p_id in Global.minigame_teams[1 - placement]:
		var node = get_node("Player"+var2str(i))
		var new_model = load(Global.character_loader.get_character_path(Global.players[p_id - 1].character)).instance()
		new_model.name = "Player" + var2str(i + 1)

		new_model.transform = node.global_transform
		node.replace_by(new_model)

		new_model.get_node("AnimationPlayer").play("sad")
		i += 1

func _on_Timer_timeout():
	Global.minigame_type = -1
	Global.minigame_teams = []
	Global._goto_scene_board()
