extends Spatial

func _ready():
	var node = $Player1
	var player_id = Global.minigame_teams[0][0]
	var character = Global.players[player_id - 1].character
	var new_model = Global.character_loader.load_character(character)

	new_model.name = "Player1"
	new_model.transform = node.global_transform
	node.replace_by(new_model)

	if Global.minigame_summary.placement:
		new_model.get_node("AnimationPlayer").play("happy")
	else:
		new_model.get_node("AnimationPlayer").play("sad")

func _on_Timer_timeout():
	Global._goto_scene_board()
