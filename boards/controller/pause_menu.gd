extends PopupPanel

export var can_save_game = false

var player_id = 0

func _ready():
	if not can_save_game:
		$Container/SaveGame.hide()

func _notification(what):
	if what == MainLoop.NOTIFICATION_WM_FOCUS_OUT and Global.pause_window_unfocus and not visible:
		player_id = 1
		popup()
		get_tree().paused = true

func _unhandled_input(event):
	if event.is_action_pressed("player1_pause"):
		if visible:
			hide()
			get_tree().paused = false
		else:
			player_id = 1
			popup()
			get_tree().paused = true
	else:
		for i in range(2, Global.amount_of_players + 1):
			if event.is_action_pressed("player" + var2str(i) + "_pause"):
				if visible:
					if player_id == i:
						hide()
						get_tree().paused = false
				else:
					player_id = i
					popup()
					get_tree().paused = true

func _save_game(save_name):
	if save_name == "":
		return
	
	Global.current_savegame.name = save_name
	for savegame in Global.savegame_loader.savegames:
		if savegame.name == save_name:
			$OverrideSave.popup()
			return
	
	Global.save_game()
	$SavegameNameInput.hide()
	_on_Resume_pressed()

func _on_Resume_pressed():
	get_tree().paused = false
	self.hide()

func _on_ExitMenu_pressed():
	get_tree().paused = false
	Global.quit_to_menu = true
	
	Global.reset_state()
	Global.goto_scene("res://menu/main_menu.tscn")

func _on_ExitDesktop_pressed():
	get_tree().quit()

func _on_SaveGame_pressed():
	if Global.is_new_savegame:
		$SavegameNameInput.popup()
	else:
		Global.save_game()
		_on_Resume_pressed()

func _on_Savegame_LineEdit_text_changed(new_text):
	$SavegameNameInput/VBoxContainer/Button.disabled = new_text.empty()

func _on_Savegame_Button_pressed():
	_save_game($SavegameNameInput/VBoxContainer/LineEdit.text)

func _on_OverrideSave_confirmed():
	Global.save_game()
	$SavegameNameInput.hide()
	_on_Resume_pressed()
