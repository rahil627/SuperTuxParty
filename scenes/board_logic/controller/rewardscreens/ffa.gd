extends Spatial

func _ready():
	var i = 0
	for p in Global.minigame_summary.placement:
		for player_id in p:
			i += 1
			var character = Global.players[player_id - 1].character
			var new_model = Global.character_loader.load_character(character)
			new_model.name = "Player" + var2str(i)
			
			add_child(new_model)
			
			var node = get_node("Placement" + var2str(i) + "/Position")
			
			new_model.transform = node.global_transform
			if new_model.has_node("AnimationPlayer"):
				if i < 4:
					new_model.get_node("AnimationPlayer").play("happy")
				else:
					new_model.get_node("AnimationPlayer").play("sad")


func _on_Timer_timeout():
	Global._goto_scene_board()
