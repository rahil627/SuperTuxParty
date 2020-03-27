extends Spatial

func _ready():
	var i = 1
	for player in Global.minigame_summary.players:
		var node = get_node("Player" + var2str(i))
		var new_model = load(Global.character_loader.get_character_path(player.character)).instance()
		new_model.name = "Player" + var2str(i + 1)

		new_model.transform = node.global_transform
		node.replace_by(new_model)

		if Global.placement:
			new_model.get_node("AnimationPlayer").play("happy")
		else:
			new_model.get_node("AnimationPlayer").play("sad")
		i += 1

func _on_Timer_timeout():
	Global._goto_scene_board()
