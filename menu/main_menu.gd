extends Container

# Path to the board being used on game start
var board = ""
var current_player = 1

# Path to the characters used on game start
var characters = []

# Player names
var names = []

var board_loader
var character_loader

var control_remapper = preload("res://menu/control_remapper.gd").new(self)

var human_players = Global.amount_of_players

func _ready():
	var award_type = $SelectionBoard/AwardType
	award_type.add_item("Linear", Global.AWARD_T.linear);
	award_type.add_item("Winner takes all", Global.AWARD_T.winner_only);
	load_boards()
	load_characters()
	control_remapper.controls_remapping_setup()
	characters.resize(Global.amount_of_players)
	
	if Global.quit_to_menu:
		Global.quit_to_menu = false
		
		$MainMenu.visible = false
		$SelectionBoard.visible = true
		
		human_players = 0
		
		var i = 1;
		
		for p in Global.players:
			if p.is_ai:
				continue
			else:
				human_players += 1
			
			get_node("PlayerInfo" + var2str(i) + "/Name").text = p.player_name;
			get_node("PlayerInfo" + var2str(i) + "/Character").text = "Character: " + p.character;
			get_node("PlayerInfo" + var2str(i) + "/Ready").text = "Ready!"
			get_node("PlayerInfo" + var2str(i)).visible = true
			
			characters[i - 1] = p.character;
			
			i += 1
		
		current_player = human_players + 1
		
		prepare_player_states()

func load_boards():
	board_loader = Global.board_loader
	character_loader = Global.character_loader
	
	var selection_board_list = $SelectionBoard/ScrollContainer/Buttons
	
	for board in board_loader.get_loaded_boards():
		var button_template = preload("res://menu/board_selection_button.tscn")
		var board_list_entry = button_template.instance()
		
		board_list_entry.set_text(board)
		board_list_entry.connect("pressed", self, "_on_board_select", [board_list_entry])
		
		selection_board_list.add_child(board_list_entry)

func load_characters():
	var selection_char_list = $SelectionChar/Buttons/VScrollBar/Grid
	var button_template = preload("res://menu/character_selection_button.tscn")
	for character in character_loader.get_loaded_characters():
		var character_list_entry = button_template.instance()
		
		var image = load(character_loader.get_character_splash(character)).get_data()
		image.resize(32, 32)
		character_list_entry.set_text(character)
		character_list_entry.icon = ImageTexture.new()
		character_list_entry.icon.create_from_image(image)
		character_list_entry.connect("pressed", self, "_on_character_select", [character_list_entry])
		
		selection_char_list.add_child(character_list_entry)

#*** Options menu ***#

func _on_Options_pressed():
	$MainMenu.hide()
	$OptionsMenu.show()

func _on_Fullscreen_toggled(button_pressed):
	OS.window_fullscreen = button_pressed

func _input(event):
	control_remapper._input(event)

func _on_Options_Back_pressed():
	$MainMenu.show()
	$OptionsMenu.hide()

func _on_Quit_pressed():
	get_tree().quit()

#*** Amount of players menu ***#

# _amount_players_selected is called when amount of players is selected
func _amount_players_selected():
	for i in range(1, human_players + 1):
		get_node("PlayerInfo" + var2str(i)).show()
	
	$SelectionPlayers.hide()
	$SelectionChar.show()

func _on_Play_pressed():
	$MainMenu.hide()
	$SelectionPlayers.show()

func _on_One_Player_pressed():
	human_players = 1
	_amount_players_selected()

func _on_Two_pressed():
	human_players = 2
	_amount_players_selected()


func _on_Three_pressed():
	human_players = 3
	_amount_players_selected()


func _on_Four_pressed():
	human_players = 4
	_amount_players_selected()

func _on_Amount_Of_Players_Back_pressed():
	$SelectionPlayers.hide()
	$MainMenu.show()

#*** Character selection menu ***#

func prepare_player_states():
	names = []
	
	for i in range(1, Global.amount_of_players + 1):
		if i < current_player:
			names.push_back(get_node("PlayerInfo" + var2str(i)).get_node("Name").text)
		else:
			var possible_characters = character_loader.get_loaded_characters()
			characters[i - 1] = possible_characters[randi() % possible_characters.size()]
			names.push_back("%s Bot" % characters[i - 1])

func _on_character_select(target):
	get_node("PlayerInfo" + var2str(current_player) + "/Character").text = "Character: " + target.get_text()
	get_node("PlayerInfo" + var2str(current_player) + "/Ready").text = "Ready!"
	
	characters[current_player - 1] = target.get_text()
	current_player += 1
	
	if current_player > human_players:
		prepare_player_states()
		
		$SelectionChar.hide()
		$SelectionBoard.show()
	
	$SelectionChar/Title.text = "Select character for Player " + var2str(current_player)

func _on_SelectionChar_Back_pressed():
	$SelectionChar.hide()
	$SelectionPlayers.show()
	
	current_player = 1
	
	$SelectionChar/Title.text = "Select character for Player 1"
	
	for i in range(1, 5):
		get_node("PlayerInfo" + var2str(i) + "/Character").text = "Character:"
		get_node("PlayerInfo" + var2str(i) + "/Ready").text = "Not ready..."
		get_node("PlayerInfo" + var2str(i)).hide()

#*** Board selection menu ***#

func _on_board_select(target):
	Global.new_game = true
	board = board_loader.get_board_path(target.get_text())
	
	Global.new_savegame()
	Global.load_board(board, names, characters, human_players)

func _on_AwardType_item_selected(ID):
	match ID:
		Global.AWARD_T.linear:
			Global.award = ID
		Global.AWARD_T.winner_only:
			Global.award = ID

func _on_Selection_Back_pressed():
	$SelectionBoard.hide()
	current_player = 1;
	
	for i in range(1, 5):
		get_node("PlayerInfo" + var2str(i) + "/Ready").text = "Not ready..."
	
	_amount_players_selected()

#*** Load game menu ***#

func _on_Load_pressed():
	for i in range(Global.savegame_loader.get_num_savegames()):
		var template = preload("res://savegames/savegame_entry.tscn").instance()
		
		var savegame = Global.savegame_loader.get_savegame(i)
		template.get_node("Load").text = savegame.name
		
		template.get_node("Load").connect("pressed", self, "_on_SaveGame_Load_pressed", [savegame])
		template.get_node("Delete").connect("pressed", self, "_on_SaveGame_Delete_pressed", [savegame, template])
		
		$LoadGameMenu/ScrollContainer/Saves.add_child(template)
	
	$MainMenu.hide()
	$LoadGameMenu.show()

func _on_SaveGame_Load_pressed(savegame):
	Global.load_board_from_savegame(savegame)

func _on_SaveGame_Delete_pressed(savegame, node):
	node.queue_free()
	
	Global.savegame_loader.delete_savegame(savegame)

func _on_LoadGame_Back_pressed():
	$LoadGameMenu.hide()
	$MainMenu.show()
