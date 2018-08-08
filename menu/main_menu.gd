extends Container

var board = "";
var current_player = 1;

func _on_Play_pressed():
	$"Main menu".hide()
	$"Selection board".show()

func _on_Options_pressed():
	$"Main menu".hide()
	$"Options menu".show()

func _on_Quit_pressed():
	get_tree().quit()

func _on_Options_Back_pressed():
	$"Main menu".show()
	$"Options menu".hide()

func _on_Selection_Back_pressed():
	$"Main menu".show()
	$"Selection board".hide()

func _on_Standard_pressed():
	$"/root/Global".new_game = true
	board = "res://boards/board.tscn";
	$"Selection board".hide()
	$"Selection char".show()
	$"PlayerInfo1".show()
	$"PlayerInfo2".show()
	$"PlayerInfo3".show()
	$"PlayerInfo4".show()

func _on_Fullscreen_toggled(button_pressed):
	OS.window_fullscreen = button_pressed

func _on_Selection_Char_Back_pressed():
	$"Selection board".show()
	$"Selection char".hide()
	$"PlayerInfo1".hide()
	$"PlayerInfo2".hide()
	$"PlayerInfo3".hide()
	$"PlayerInfo4".hide()

func _on_Tux_pressed():
	get_node("PlayerInfo" + var2str(current_player)).get_node("Character").text = "Character: Tux"
	get_node("PlayerInfo" + var2str(current_player)).get_node("Ready").text = "Ready!"
	
	current_player += 1
	
	if current_player > $"/root/Global".amount_of_players:
		$"/root/Global".goto_scene(board);
	
	$"Selection char/Title".text = "Select character for Player " + var2str(current_player);
