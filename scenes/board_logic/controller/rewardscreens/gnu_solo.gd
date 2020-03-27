extends Spatial

func _ready():
	var node = $Player1
	var new_model = load(Global.character_loader.get_character_path(Global.players[Global.minigame_teams[0][0] - 1].character)).instance()

	new_model.name = "Player1"
	new_model.transform = node.global_transform
	node.replace_by(new_model)

	if Global.minigame_summary.placement:
		new_model.get_node("AnimationPlayer").play("happy")
	else:
		new_model.get_node("AnimationPlayer").play("sad")

func _on_Timer_timeout():
	Global._goto_scene_board()
