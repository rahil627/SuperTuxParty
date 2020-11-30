extends Control

# Path to the board being used on game start.
var board := ""
var current_player := 1

# Path to the characters used on game start.
var characters := []

# Player names.
var names := []

var board_loader
var character_loader

var human_players := 0

func _ready() -> void:
	# Wait with main menu music until audio options have been loaded
	$AudioStreamPlayer.play()
	var award_type = $BoardSettings/Options/Award/AwardType
	award_type.add_item("MENU_LABEL_LINEAR", Global.AWARD_TYPE.LINEAR)
	award_type.add_item("MENU_LABEL_WINNER_TAKES_ALL", Global.AWARD_TYPE.WINNER_ONLY);
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

		var i := 1;

		for p in Global.players:
			if p.is_ai:
				continue
			else:
				human_players += 1

			get_node("PlayerInfo" + str(i) + "/Name").text = p.player_name;
			get_node("PlayerInfo" + str(i) + "/Character").text =\
					tr("MENU_LABEL_CHARACTER") + " " + p.character;
			get_node("PlayerInfo" + str(i) + "/Ready").text =\
					tr("MENU_LABEL_READY")
			get_node("PlayerInfo" + str(i)).visible = true

			characters[i - 1] = p.character;

			i += 1

		current_player = human_players + 1

		prepare_player_states()

func load_boards() -> void:
	board_loader = PluginSystem.board_loader
	character_loader = PluginSystem.character_loader

	var selection_board_list := $SelectionBoard/ScrollContainer/Buttons as\
			VBoxContainer

	var button_template: PackedScene =\
			preload("res://scenes/sound_button/sound_button.tscn")
	for board in board_loader.get_loaded_boards():
		var board_list_entry: Button = button_template.instance()
		board_list_entry.size_flags_horizontal = SIZE_EXPAND_FILL

		board_list_entry.set_text(board)
		board_list_entry.connect(
				"pressed", self, "_on_board_select", [board_list_entry])

		selection_board_list.add_child(board_list_entry)

func load_characters() -> void:
	var selection_char_list := $SelectionChar/Buttons/VScrollBar/Grid as\
			GridContainer
	var button_template: PackedScene =\
			preload("res://scenes/sound_button/sound_button.tscn")
	for character in character_loader.get_loaded_characters():
		var character_list_entry: Button = button_template.instance()
		character_list_entry.size_flags_horizontal = SIZE_EXPAND_FILL

		character_list_entry.set_text(character)
		character_list_entry.icon = character_loader.load_character_icon(character)
		character_list_entry.expand_icon = true
		character_list_entry.connect("pressed", self, "_on_character_select",
				[character_list_entry])

		selection_char_list.add_child(character_list_entry)

#*** Options menu ***#

func _on_Options_pressed() -> void:
	$MainMenu.hide()
	$OptionsMenu.show()
	$OptionsMenu/OptionsMenu/Menu/Back.grab_focus()

func _on_OptionsMenu_quit() -> void:
	$MainMenu.show()
	$OptionsMenu.hide()
	$MainMenu/Buttons/Options.grab_focus()

#*** Amount of players menu ***#

func _select_player_amount(players) -> void:
	human_players = players
	for i in range(1, human_players + 1):
		get_node("PlayerInfo" + var2str(i)).show()

	$SelectionPlayers.hide()
	$SelectionChar.show()
	if $SelectionChar/Buttons/VScrollBar/Grid.get_child_count() > 0:
		$SelectionChar/Buttons/VScrollBar/Grid.get_child(0).grab_focus()
	else:
		$SelectionChar/Buttons/Back.grab_focus()

func _on_Play_pressed() -> void:
	$MainMenu.hide()
	$SelectionPlayers.show()
	$SelectionPlayers/Buttons/VScrollBar/Grid/One.grab_focus()

func _on_Amount_Of_Players_Back_pressed() -> void:
	$SelectionPlayers.hide()
	$MainMenu.show()
	$MainMenu/Buttons/Play.grab_focus()

#*** Character selection menu ***#

func prepare_player_states() -> void:
	names.clear()

	var possible_characters: Array = character_loader.get_loaded_characters()
	var num_characters: int = possible_characters.size()
	if num_characters >= Global.amount_of_players:
		for i in characters:
			if i == null:
				break

			possible_characters.remove(possible_characters.find(i))

	for i in range(1, Global.amount_of_players + 1):
		if i < current_player:
			names.push_back(
					get_node("PlayerInfo" + var2str(i)).get_node("Name").text)
		else:
			var idx: int = randi() % possible_characters.size()
			characters[i - 1] = possible_characters[idx]
			if num_characters >= Global.amount_of_players:
				possible_characters.remove(idx)
			names.push_back("%s Bot" % characters[i - 1])

func _on_character_select(target: Button) -> void:
	get_node("PlayerInfo" + str(current_player) + "/Character").text =\
			tr("MENU_LABEL_CHARACTER") + " " + target.get_text()
	get_node("PlayerInfo" + str(current_player) + "/Ready").text =\
			tr("MENU_LABEL_READY")

	characters[current_player - 1] = target.get_text()
	current_player += 1

	if PluginSystem.character_loader.get_loaded_characters().size() >=\
			Global.amount_of_players:
		target.disabled = true

	if current_player > human_players:
		prepare_player_states()

		$SelectionChar.hide()
		$SelectionBoard.show()
		if $SelectionBoard/ScrollContainer/Buttons.get_child_count() > 0:
			$SelectionBoard/ScrollContainer/Buttons.get_child(0).grab_focus()
		else:
			$SelectionBoard/Back.grab_focus()

	$SelectionChar/Title.text =\
			tr("MENU_LABEL_SELECT_CHARACTER_PLAYER_" + var2str(current_player))

func _on_SelectionChar_Back_pressed() -> void:
	$SelectionChar.hide()
	$SelectionPlayers.show()
	$SelectionPlayers/Buttons/VScrollBar/Grid/One.grab_focus()

	current_player = 1

	$SelectionChar/Title.text = tr("MENU_LABEL_SELECT_CHARACTER_PLAYER_1")

	for i in range(1, 5):
		get_node("PlayerInfo" + str(i) + "/Character").text =\
				tr("MENU_LABEL_CHARACTER")
		get_node("PlayerInfo" + str(i) + "/Ready").text =\
				tr("MENU_LABEL_NOT_READY_ELLIPSIS")
		get_node("PlayerInfo" + str(i)).hide()

	# Reenable all characters.
	for child in $SelectionChar/Buttons/VScrollBar/Grid.get_children():
		child.disabled = false

#*** Board selection menu ***#

func _on_board_select(target: Button) -> void:
	board = board_loader.get_board_path(target.get_text())

	$SelectionBoard.hide()
	$BoardSettings.show()
	$BoardSettings/Start.grab_focus()

	var cake_cost: int = 30
	var turns: int = 10

	var scene: SceneState = load(board).get_state()
	for i in range(scene.get_node_count()):
		var instance: PackedScene = scene.get_node_instance(i)
		if instance:
			var groups: PoolStringArray = instance.get_state().get_node_groups(0)
			for group in groups:
				if group == "Controller":
					for prop in range(scene.get_node_property_count(i)):
						match scene.get_node_property_name(i, prop):
							"COOKIES_FOR_CAKE":
								cake_cost = int(scene.get_node_property_value(i, prop))
							"MAX_TURNS":
								turns = int(scene.get_node_property_value(i, prop))

	$BoardSettings/Options/CakeCost/SpinBox.value = cake_cost
	$BoardSettings/Options/Turns/SpinBox.value = turns

func _on_Selection_Back_pressed() -> void:
	$SelectionBoard.hide()
	current_player = 1;
	$SelectionChar/Title.text = tr("MENU_LABEL_SELECT_CHARACTER_PLAYER_1")

	for i in range(1, 5):
		get_node("PlayerInfo" + str(i) + "/Ready").text =\
				tr("MENU_LABEL_NOT_READY_ELLIPSIS")

	# Reenable all characters.
	for child in $SelectionChar/Buttons/VScrollBar/Grid.get_children():
		child.disabled = false

	characters.clear()
	characters.resize(Global.amount_of_players)

	_select_player_amount(human_players)
	if $SelectionChar/Buttons/VScrollBar/Grid.get_child_count() > 0:
		$SelectionChar/Buttons/VScrollBar/Grid.get_child(0).grab_focus()
	else:
		$SelectionChar/Buttons/Back.grab_focus()

#*** Load game menu ***#

func _on_Load_pressed() -> void:
	var savegame_template: PackedScene =\
			preload("res://savegames/savegame_entry.tscn")
	for i in Global.savegame_loader.get_num_savegames():
		var savegame_entry := savegame_template.instance() as Control
		var savegame: SaveGameLoader.SaveGame =\
				Global.savegame_loader.get_savegame(i)
		savegame_entry.get_node("Load").text = savegame.name

		savegame_entry.get_node("Load").connect("pressed", self,
				"_on_SaveGame_Load_pressed", [savegame])
		savegame_entry.get_node("Delete").connect("pressed", self,
				"_on_SaveGame_Delete_pressed", [savegame, savegame_entry])

		$LoadGameMenu/ScrollContainer/Saves.add_child(savegame_entry)

	$MainMenu.hide()
	$LoadGameMenu.show()
	if $LoadGameMenu/ScrollContainer/Saves.get_child_count() > 0:
			$LoadGameMenu/ScrollContainer/Saves.\
					get_child(0).get_child(0).grab_focus()
	else:
		$LoadGameMenu/Back.grab_focus()

func _on_SaveGame_Load_pressed(savegame: SaveGameLoader.SaveGame) -> void:
	Global.load_board_from_savegame(savegame)

func _on_SaveGame_Delete_pressed(savegame: SaveGameLoader.SaveGame,
		node: Control) -> void:
	var index: int = node.get_index()
	node.queue_free()
	$LoadGameMenu/ScrollContainer/Saves.remove_child(node)

	var num_children: int =\
			$LoadGameMenu/ScrollContainer/Saves.get_child_count()
	if num_children > 0:
		# warning-ignore:narrowing_conversion
		$LoadGameMenu/ScrollContainer/Saves.get_child(
				min(index, num_children - 1)).get_child(0).grab_focus()
	else:
		$LoadGameMenu/Back.grab_focus()

	Global.savegame_loader.delete_savegame(savegame)

func _on_LoadGame_Back_pressed() -> void:
	for i in $LoadGameMenu/ScrollContainer/Saves.get_children():
		i.queue_free()

	$LoadGameMenu.hide()
	$MainMenu.show()
	$MainMenu/Buttons/Load.grab_focus()

func _on_Quit_pressed() -> void:
	get_tree().quit()

func _on_BoardSettings_Back_pressed():
	$BoardSettings.hide()
	$SelectionBoard.show()

	if $SelectionBoard/ScrollContainer/Buttons.get_child_count() > 0:
		$SelectionBoard/ScrollContainer/Buttons.get_child(0).grab_focus()
	else:
		$SelectionBoard/Back.grab_focus()

func _on_BoardSettings_Start_pressed():
	Global.overrides.cake_cost = int($BoardSettings/Options/CakeCost/SpinBox.value)
	Global.overrides.max_turns = int($BoardSettings/Options/Turns/SpinBox.value)
	Global.overrides.ai_difficulty = $BoardSettings/Options/Difficulty/OptionButton.get_selected_id()
	Global.overrides.award = $BoardSettings/Options/Award/AwardType.selected

	Global.new_game = true
	Global.new_savegame()
	Global.load_board(board, names, characters, human_players)

#*** Credits menu ***#
func process_hyperlinks(input: String) -> String:
	var out := ""
	
	var pos = input.find("[")
	while pos != -1:
		var end = input.find("]")
		if end != -1 and input[end+1] == "(":
			var urlend = input.find(")", end+1)
			out += input.substr(0, pos)
			out += "[color=#00aaff][url=" + input.substr(end+2, urlend - end - 2) + "]" \
					+ input.substr(pos + 1, end - pos - 1) + "[/url][/color]"
			input = input.substr(urlend+1, input.length() - urlend)
		else:
			out += input.substr(0, pos+1)
			input = input.substr(pos+1, input.length() - pos)
		pos = input.find("[")
	out += input
	return out

func print_licenses(f: File) -> String:
	var text = ""
	
	var current_dir := ""
	var has_files = true
	while not f.eof_reached():
		var line := f.get_line()
		if line.begins_with("## "):
			current_dir = line.substr(3, line.length() - 3)
			if not current_dir.ends_with("/"):
				current_dir += "/"
			has_files = false
		elif line.begins_with("### "):
			var unescaped := line.substr(4, line.length() - 4).replace("\\*", "*")
			var files = unescaped.split("|")
			for file in files:
				text += "[color=#cc00ff]" + current_dir + file.lstrip(" \t\v").rstrip(" \t\v") + ":[/color]\n"
			has_files = true
		else:
			if not has_files: # Special edge case: toplevel entries start with '## '
				text += "[color=#cc00ff]" + current_dir.substr(0, current_dir.length() - 1) + ":[/color]\n"
				has_files = true
			text += "[indent]" + process_hyperlinks(line) + '[/indent]\n'
	
	return text

func _on_Credits_pressed():
	var text = """[center]SuperTuxParty is brought to you by:[/center]
[color=#ffaa00][center]Dragoncraft89, Antiwrapper, [url=https://yeldham.itch.io]Yeldham[/url], RiderExMachina, hejka26, airon90, swolfschristophe, pastmidnight14 and kratz00[/center][/color]

[center]with [color=#66aa00]ART[/color] by:[/center]
"""
	
	var license_art := File.new()
	license_art.open("res://LICENSE-ART.md", File.READ)
	text += print_licenses(license_art)
	license_art.close()
	
	text += "[center]and [color=#66aa00]MUSIC[/color] by:[/center]\n"
	
	var license_music := File.new()
	license_music.open("res://LICENSE-MUSIC.md", File.READ)
	text += print_licenses(license_music)
	license_music.close()
	
	text += "[center][color=#66aa00]SHADERS[/color] by:[/center]\n"

	var license_shader := File.new()
	license_shader.open("res://LICENSE-SHADER.md", File.READ)
	text += print_licenses(license_shader)
	license_shader.close()
	
	$CreditsMenu/PanelContainer/RichTextLabel.bbcode_text = text
	$CreditsMenu.show()
	$MainMenu.hide()
	$CreditsMenu/Back.grab_focus()

func _on_Credits_meta_clicked(meta):
	OS.shell_open(meta) # Open links in the credits

func _on_Credits_Back_pressed():
	$MainMenu.show()
	$CreditsMenu.hide()
	
	$MainMenu/Buttons/Play.grab_focus()

func _on_Screenshots_pressed():
	OS.shell_open("file://{0}/screenshots".format([OS.get_user_data_dir()]))
