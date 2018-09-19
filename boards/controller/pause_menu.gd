extends PopupPanel

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
	
	Global.reset_state()
	Global.goto_scene("res://menu/main_menu.tscn")

func _on_ExitDesktop_pressed():
	get_tree().quit()
