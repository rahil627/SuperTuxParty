extends PopupPanel

func _on_Resume_pressed():
	get_tree().paused = false
	self.hide()

func _on_ExitMenu_pressed():
	get_tree().paused = false
	
	var g = $"/root/Global"
	
	g.reset_state()
	g.goto_scene("res://menu/main_menu.tscn")

func _on_ExitDesktop_pressed():
	get_tree().quit()
