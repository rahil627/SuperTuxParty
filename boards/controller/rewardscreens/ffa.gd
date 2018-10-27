extends Spatial

func _ready():
	var i = 0
	for player_id in Global.placement:
		i += 1
		var new_model = load(Global.character_loader.get_character_path(Global.players[player_id - 1].character)).instance()
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
	Global.minigame_type = null
	Global.minigame_teams = null
	Global.call_deferred("_goto_scene_ingame", Global.current_board)
