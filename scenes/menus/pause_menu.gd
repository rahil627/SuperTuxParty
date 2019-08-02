extends PopupPanel

export var can_save_game := false

var player_id := 0
var paused := false

var was_already_paused: bool

func _ready() -> void:
	if not can_save_game:
		$Container/SaveGame.hide()
	get_tree().connect("screen_resized", self, "_fix_size")

func pause() -> void:
	UISound.stream = preload("res://assets/sounds/ui/rollover2.wav")
	UISound.play()
	popup()
	was_already_paused = get_tree().paused
	paused = true
	get_tree().paused = true

func unpause() -> void:
	hide()
	get_tree().paused = was_already_paused
	paused = false
	was_already_paused = false

func _notification(what: int) -> void:
	if what == MainLoop.NOTIFICATION_WM_FOCUS_OUT and\
			Global.pause_window_unfocus and not paused:
		player_id = 1
		pause()

func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("player1_pause"):
		if visible:
			unpause()
		else:
			player_id = 1
			pause()
	else:
		for i in range(2, Global.amount_of_players + 1):
			if event.is_action_pressed("player" + var2str(i) + "_pause"):
				if visible:
					if player_id == i:
						unpause()
				else:
					player_id = i
					pause()

func _save_game(save_name: String) -> void:
	if save_name == "":
		return

	Global.current_savegame.name = save_name
	for savegame in Global.savegame_loader.savegames:
		if savegame.name == save_name:
			$OverrideSave.popup_centered()
			return

	Global.save_game()
	$SavegameNameInput.hide()
	_on_Resume_pressed()

func _on_Resume_pressed() -> void:
	unpause()

func _on_ExitMenu_pressed() -> void:
	unpause()
	Global.quit_to_menu = true

	Global.reset_state()
	Global.goto_scene("res://scenes/menus/main_menu.tscn")

func _on_ExitDesktop_pressed() -> void:
	get_tree().quit()

func _on_SaveGame_pressed() -> void:
	if Global.is_new_savegame:
		$SavegameNameInput.popup_centered()
		$SavegameNameInput/VBoxContainer/LineEdit.grab_focus()
	else:
		Global.save_game()
		_on_Resume_pressed()

func _on_Savegame_LineEdit_text_changed(new_text) -> void:
	$SavegameNameInput/VBoxContainer/Button.disabled = new_text.empty()

func _on_Savegame_Button_pressed() -> void:
	_save_game($SavegameNameInput/VBoxContainer/LineEdit.text)

func _on_OverrideSave_confirmed() -> void:
	Global.save_game()
	$SavegameNameInput.hide()
	_on_Resume_pressed()

func _on_Options_pressed() -> void:
	$OptionsWindow.popup()

func _on_OptionsMenu_quit() -> void:
	$OptionsWindow.hide()

func _fix_size() -> void:
	popup_centered()
