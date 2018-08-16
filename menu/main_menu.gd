extends Container

# path to the board being used on game start
var board = ""
var current_player = 1

# path to the characters used on game start
var characters = []

var board_loader
var character_loader

var ControlRemapper = preload("res://menu/controlremapper.gd")
var control_remapper = ControlRemapper.new(self)

func load_boards():
	board_loader = get_node("/root/Global").board_loader
	character_loader = get_node("/root/Global").character_loader
	
	var selection_board_list = get_node("Selection board/ScrollContainer/Buttons")
	
	for board in board_loader.get_loaded_boards():
		var button_template = preload("res://menu/board_selection_button.tscn")
		var board_list_entry = button_template.instance()
		
		board_list_entry.set_text(board)
		board_list_entry.connect("pressed", self, "_on_board_select", [board_list_entry])
		
		selection_board_list.add_child(board_list_entry)

func load_characters():
	var selection_char_list = get_node("Selection char/Buttons/VScrollBar/Grid")
	for character in character_loader.get_loaded_characters():
		var button_template = preload("res://menu/character_selection_button.tscn")
		var character_list_entry = button_template.instance()
		
		var image = ResourceLoader.load(character_loader.get_character_splash(character)).get_data()
		image.resize(32, 32)
		character_list_entry.set_text(character)
		character_list_entry.icon = ImageTexture.new()
		character_list_entry.icon.create_from_image(image)
		character_list_entry.connect("pressed", self, "_on_character_select", [character_list_entry])
		
		selection_char_list.add_child(character_list_entry)

func _ready():
	$"Selection board/AwardType".add_item("Linear", 0);
	$"Selection board/AwardType".add_item("Winner takes all", 1);
	load_boards()
	load_characters()
	control_remapper.controls_remapping_setup()
	characters.resize($"/root/Global".amount_of_players)

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

func _on_character_select(target):
	get_node("PlayerInfo" + var2str(current_player)).get_node("Character").text = "Character: " + target.get_text()
	get_node("PlayerInfo" + var2str(current_player)).get_node("Ready").text = "Ready!"
	
	characters[current_player - 1] = target.get_text()
	current_player += 1
	
	if current_player > $"/root/Global".amount_of_players:
		var names = []
		
		for i in range(1, current_player):
			names.push_back(get_node("PlayerInfo" + var2str(i)).get_node("Name").text)
		
		$"/root/Global".load_board(board, names, characters)
	
	$"Selection char/Title".text = "Select character for Player " + var2str(current_player)

func _on_AwardType_item_selected(ID):
	if ID == 0: # Linear
		$"/root/Global".award = $"/root/Global".AWARD_T.linear
	elif ID == 1: # Winner takes all
		$"/root/Global".award = $"/root/Global".AWARD_T.winner_only
