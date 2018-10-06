extends PopupPanel

export(bool) var can_save_game = false

func _ready():
	if not can_save_game:
		$Container/SaveGame.hide()

func _unhandled_input(event):
	if event.is_action_pressed("pause"):
		if visible:
			hide()
			get_tree().paused = false
		else:
			popup()
			get_tree().paused = true

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

func _on_Button_pressed():
	var text = $SavegameNameInput/VBoxContainer/TextEdit.text
	if text.length() > 0:
		Global.current_savegame.name = text
		for savegame in Global.savegame_loader.savegames:
			if savegame.name == text:
				$OverrideSave.popup()
				return
		
		Global.save_game()
		$SavegameNameInput.hide()
		_on_Resume_pressed()

func _on_OverrideSave_confirmed():
	Global.save_game()
	$SavegameNameInput.hide()
	_on_Resume_pressed()
