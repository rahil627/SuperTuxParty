extends Container

# path to the board being used on game start
var board = ""
var current_player = 1

var PluginSystem = preload("res://pluginsystem.gd")
var plugin_system = PluginSystem.new()

var BoardLoader = preload("res://boards/boardloader.gd")
var board_loader = BoardLoader.new()

var ControlRemapper = preload("res://menu/controlremapper.gd")
var control_remapper = ControlRemapper.new(self)

func load_boards():
	var selection_board_list = get_node("Selection board/ScrollContainer/Buttons")
	for board in board_loader.get_loaded_boards():
		var button_template = preload("res://menu/board_selection_button.tscn")
		var board_list_entry = button_template.instance()
		board_list_entry.set_text(board)
		board_list_entry.connect("pressed", self, "_on_board_select", [board_list_entry])
		selection_board_list.add_child(board_list_entry)

func _ready():
	load_boards()
	control_remapper.controls_remapping_setup()

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

func _on_board_select(target):
	$"/root/Global".new_game = true
	board = board_loader.get_board_path(target.get_text())
	$"Selection board".hide()
	$"Selection char".show()
	$"PlayerInfo1".show()
	$"PlayerInfo2".show()
	$"PlayerInfo3".show()
	$"PlayerInfo4".show()

func _on_Fullscreen_toggled(button_pressed):
	OS.window_fullscreen = button_pressed

func _input(event):
	control_remapper._input(event)

func _on_Selection_Char_Back_pressed():
	$"Selection board".show()
	$"Selection char".hide()
	
	current_player = 1
	
	$"Selection char/Title".text = "Select character for Player 1"
	
	for i in range(1, 4):
		get_node("PlayerInfo" + var2str(i)).get_node("Character").text = "Character:"
		get_node("PlayerInfo" + var2str(i)).get_node("Ready").text = "Not ready..."
	
	$"PlayerInfo1".hide()
	$"PlayerInfo2".hide()
	$"PlayerInfo3".hide()
	$"PlayerInfo4".hide()

func _on_Tux_pressed():
	get_node("PlayerInfo" + var2str(current_player)).get_node("Character").text = "Character: Tux"
	get_node("PlayerInfo" + var2str(current_player)).get_node("Ready").text = "Ready!"
	
	current_player += 1
	
	if current_player > $"/root/Global".amount_of_players:
		$"/root/Global".load_board(board)
	
	$"Selection char/Title".text = "Select character for Player " + var2str(current_player)
