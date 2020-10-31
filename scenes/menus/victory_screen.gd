extends Spatial

signal return_to_menu

func _input(event):
	if event.is_action_pressed("player1_ok"):
		emit_signal("return_to_menu")

func _ready():
	for i in range(1, Global.amount_of_players+1):
		var new_model = PluginSystem.character_loader.load_character(Global.players[i - 1].character)
		new_model.name = "Model"
		
		get_node("Player" + str(i)).add_child(new_model)
		
		$Summary/Stats/Names/Entries.get_node("Player" + str(i)).text = Global.players[i - 1].player_name
		$Summary/Stats/Cakes/Entries.get_node("Player" + str(i)).text = str(Global.players[i - 1].cakes)
		$Summary/Stats/Cookies/Entries.get_node("Player" + str(i)).text = str(Global.players[i - 1].cookies)
	
	$Player1/Model.play_animation("happy")
	$Player2/Model.play_animation("happy")
	$Player3/Model.play_animation("happy")
	$Player4/Model.play_animation("happy")
	
	var winner = []
	for player in Global.players:
		if not winner or (winner[0].cakes < player.cakes or (winner[0].cakes == player.cakes and winner[0].cookies < player.cookies)):
			winner = [player]
		elif winner and winner[0].cakes == player.cakes and winner[0].cookies == player.cookies:
			winner.append(player)
	
	var winner_names = []
	for w in winner:
		winner_names.append(w.player_name)
	
	yield(get_tree().create_timer(1), "timeout")
	
	$Scene/AnimationPlayer.play("KeyAction")
	
	yield(get_tree().create_timer(2), "timeout")
	
	var sara_tex = preload("res://scenes/board_logic/controller/icons/sara.png")
	$SpeechDialog.show_dialog("CONTEXT_SPEAKER_SARA", sara_tex, tr("CONTEXT_WINNER_ANNOUNCEMENT"), 1)
	yield($SpeechDialog, "dialog_finished")
	
	$AudioStreamPlayer2/AnimationPlayer.play("fade_out")
	yield(get_tree().create_timer(1), "timeout")
	$AudioStreamPlayer.play()
	
	var pos = Vector3(-(len(winner) - 1) / 2.0, 0, 2)
	for w in winner:
		var player = get_node("Player" + str(w.player_id))
		player.destination = pos
		player.get_node("Model").play_animation("run")
		pos.x += 1.0
	
	match len(winner):
		1: $SpeechDialog.show_dialog("CONTEXT_SPEAKER_SARA", sara_tex, tr("CONTEXT_WINNER_REVEAL_ONE_PLAYER").format(winner_names), 1)
		2: $SpeechDialog.show_dialog("CONTEXT_SPEAKER_SARA", sara_tex, tr("CONTEXT_WINNER_REVEAL_TWO_PLAYER").format(winner_names), 1)
		3: $SpeechDialog.show_dialog("CONTEXT_SPEAKER_SARA", sara_tex, tr("CONTEXT_WINNER_REVEAL_THREE_PLAYER").format(winner_names), 1)
		4: $SpeechDialog.show_dialog("CONTEXT_SPEAKER_SARA", sara_tex, tr("CONTEXT_WINNER_REVEAL_FOUR_PLAYER").format(winner_names), 1)
	$CameraMovement.play("closeup")
	
	yield($SpeechDialog, "dialog_finished")
	$Summary.show()
	
	yield(self, "return_to_menu")
	
	Global.quit_to_menu = true
	Global.reset_state()
	Global.goto_scene("res://scenes/menus/main_menu.tscn")
