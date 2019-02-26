extends Control

# Path to the board being used on game start
var board = ""
var current_player = 1

# Path to the characters used on game start
var characters = []

# Player names
var names = []

var board_loader
var character_loader

var human_players = 0

func _ready():
	var award_type = $SelectionBoard/AwardType
	award_type.add_item(tr("MENU_LABEL_LINEAR"), Global.AWARD_TYPE.LINEAR);
	award_type.add_item(tr("MENU_LABEL_WINNER_TAKES_ALL"), Global.AWARD_TYPE.WINNER_ONLY);
	load_boards()
	load_characters()
	characters.resize(Global.amount_of_players)
	
	$MainMenu/Buttons/Play.grab_focus()
	
	if Global.quit_to_menu:
		Global.quit_to_menu = false
		
		$MainMenu.visible = false
		$SelectionBoard.visible = true
		if $SelectionBoard/ScrollContainer/Buttons.get_child_count() > 0:
			$SelectionBoard/ScrollContainer/Buttons.get_child(0).grab_focus()
		else:
			$SelectionBoard/Back.grab_focus()
		
		var i = 1;
		
		for p in Global.players:
			if p.is_ai:
				continue
			else:
				human_players += 1
			
			get_node("PlayerInfo" + var2str(i) + "/Name").text = p.player_name;
			get_node("PlayerInfo" + var2str(i) + "/Character").text = tr("MENU_LABEL_CHARACTER") + " " + p.character;
			get_node("PlayerInfo" + var2str(i) + "/Ready").text = tr("MENU_LABEL_READY")
			get_node("PlayerInfo" + var2str(i)).visible = true
			
			characters[i - 1] = p.character;
			
			i += 1
		
		current_player = human_players + 1
		
		prepare_player_states()

func load_boards():
	board_loader = Global.board_loader
	character_loader = Global.character_loader
	
	var selection_board_list = $SelectionBoard/ScrollContainer/Buttons
	
	var button_template = preload("res://scenes/menus/board_selection_button.tscn")
	for board in board_loader.get_loaded_boards():
		var board_list_entry = button_template.instance()
		
		board_list_entry.set_text(board)
		board_list_entry.connect("pressed", self, "_on_board_select", [board_list_entry])
		
		selection_board_list.add_child(board_list_entry)

func load_characters():
	var selection_char_list = $SelectionChar/Buttons/VScrollBar/Grid
	var button_template = preload("res://scenes/menus/character_selection_button.tscn")
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
	$OptionsMenu/OptionsMenu/Back.grab_focus()

func _on_OptionsMenu_quit():
	$MainMenu.show()
	$OptionsMenu.hide()
	$MainMenu/Buttons/Options.grab_focus()

#*** Amount of players menu ***#

func _select_player_amount(players):
	human_players = players
	for i in range(1, human_players + 1):
		get_node("PlayerInfo" + var2str(i)).show()
	
	$SelectionPlayers.hide()
	$SelectionChar.show()
	if $SelectionChar/Buttons/VScrollBar/Grid.get_child_count() > 0:
		$SelectionChar/Buttons/VScrollBar/Grid.get_child(0).grab_focus()
	else:
		$SelectionChar/Buttons/Back.grab_focus()

func _on_Play_pressed():
	$MainMenu.hide()
	$SelectionPlayers.show()
	$SelectionPlayers/Buttons/VScrollBar/Grid/One.grab_focus()

func _on_Amount_Of_Players_Back_pressed():
	$SelectionPlayers.hide()
	$MainMenu.show()
	$MainMenu/Buttons/Play.grab_focus()

#*** Character selection menu ***#

func prepare_player_states():
	names = []
	
	var possible_characters = character_loader.get_loaded_characters()
	var num_characters = possible_characters.size()
	if num_characters >= Global.amount_of_players:
		for i in characters:
			if i == null:
				break
			
			possible_characters.remove(possible_characters.find(i))
	
	for i in range(1, Global.amount_of_players + 1):
		if i < current_player:
			names.push_back(get_node("PlayerInfo" + var2str(i)).get_node("Name").text)
		else:
			var idx = randi() % possible_characters.size()
			characters[i - 1] = possible_characters[idx]
			if num_characters >= Global.amount_of_players:
				possible_characters.remove(idx)
			names.push_back("%s Bot" % characters[i - 1])

func _on_character_select(target):
	get_node("PlayerInfo" + var2str(current_player) + "/Character").text = tr("MENU_LABEL_CHARACTER") + " " + target.get_text()
	get_node("PlayerInfo" + var2str(current_player) + "/Ready").text = tr("MENU_LABEL_READY")
	
	characters[current_player - 1] = target.get_text()
	current_player += 1
	
	if Global.character_loader.get_loaded_characters().size() >= Global.amount_of_players:
		target.disabled = true
	
	if current_player > human_players:
		prepare_player_states()
		
		$SelectionChar.hide()
		$SelectionBoard.show()
		if $SelectionBoard/ScrollContainer/Buttons.get_child_count() > 0:
			$SelectionBoard/ScrollContainer/Buttons.get_child(0).grab_focus()
		else:
			$SelectionBoard/Back.grab_focus()
	
	$SelectionChar/Title.text = tr("MENU_LABEL_SELECT_CHARACTER_PLAYER_" + var2str(current_player))

func _on_SelectionChar_Back_pressed():
	$SelectionChar.hide()
	$SelectionPlayers.show()
	$SelectionPlayers/Buttons/VScrollBar/Grid/One.grab_focus()
	
	current_player = 1
	
	$SelectionChar/Title.text = tr("MENU_LABEL_SELECT_CHARACTER_PLAYER_1")
	
	for i in range(1, 5):
		get_node("PlayerInfo" + var2str(i) + "/Character").text = tr("MENU_LABEL_CHARACTER")
		get_node("PlayerInfo" + var2str(i) + "/Ready").text = tr("MENU_LABEL_NOT_READY_ELLIPSIS")
		get_node("PlayerInfo" + var2str(i)).hide()
	
	# Reenable all characters
	for child in $SelectionChar/Buttons/VScrollBar/Grid.get_children():
		child.disabled = false

#*** Board selection menu ***#

func _on_board_select(target):
	Global.new_game = true
	board = board_loader.get_board_path(target.get_text())
	
	Global.new_savegame()
	Global.load_board(board, names, characters, human_players)

func _on_AwardType_item_selected(ID):
	match ID:
		Global.AWARD_TYPE.LINEAR:
			Global.award = ID
		Global.AWARD_TYPE.WINNER_ONLY:
			Global.award = ID

func _on_Selection_Back_pressed():
	$SelectionBoard.hide()
	current_player = 1;
	
	for i in range(1, 5):
		get_node("PlayerInfo" + var2str(i) + "/Ready").text = tr("MENU_LABEL_NOT_READY_ELLIPSIS")
	
	# Reenable all characters
	for child in $SelectionChar/Buttons/VScrollBar/Grid.get_children():
		child.disabled = false
	
	characters.clear()
	characters.resize(Global.amount_of_players)
	
	_select_player_amount(0)
	if $SelectionChar/Buttons/VScrollBar/Grid.get_child_count() > 0:
		$SelectionChar/Buttons/VScrollBar/Grid.get_child(0).grab_focus()
	else:
		$SelectionChar/Buttons/Back.grab_focus()

#*** Load game menu ***#

func _on_Load_pressed():
	var savegame_template = preload("res://savegames/savegame_entry.tscn")
	for i in range(Global.savegame_loader.get_num_savegames()):
		var savegame_entry = savegame_template.instance()
		var savegame = Global.savegame_loader.get_savegame(i)
		savegame_entry.get_node("Load").text = savegame.name
		
		savegame_entry.get_node("Load").connect("pressed", self, "_on_SaveGame_Load_pressed", [savegame])
		savegame_entry.get_node("Delete").connect("pressed", self, "_on_SaveGame_Delete_pressed", [savegame, savegame_entry])
		
		$LoadGameMenu/ScrollContainer/Saves.add_child(savegame_entry)
	
	$MainMenu.hide()
	$LoadGameMenu.show()
	if $LoadGameMenu/ScrollContainer/Saves.get_child_count() > 0:
			$LoadGameMenu/ScrollContainer/Saves.get_child(0).get_child(0).grab_focus()
	else:
		$LoadGameMenu/Back.grab_focus()

func _on_SaveGame_Load_pressed(savegame):
	Global.load_board_from_savegame(savegame)

func _on_SaveGame_Delete_pressed(savegame, node):
	var index = node.get_index()
	node.queue_free()
	$LoadGameMenu/ScrollContainer/Saves.remove_child(node)
	
	var num_children = $LoadGameMenu/ScrollContainer/Saves.get_child_count()
	if num_children > 0:
		$LoadGameMenu/ScrollContainer/Saves.get_child(min(index, num_children)).get_child(0).grab_focus()
	else:
		$LoadGameMenu/Back.grab_focus()
	
	Global.savegame_loader.delete_savegame(savegame)

func _on_LoadGame_Back_pressed():
	for i in $LoadGameMenu/ScrollContainer/Saves.get_children():
		i.queue_free()
	
	$LoadGameMenu.hide()
	$MainMenu.show()
	$MainMenu/Buttons/Load.grab_focus()

func _on_Quit_pressed():
	get_tree().quit()
