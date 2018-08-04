extends Container

func _on_Play_pressed():
	get_tree().change_scene("res://levels/board/board.tscn");


func _on_Options_pressed():
	print("Not implemented!");


func _on_Quit_pressed():
	get_tree().quit();
