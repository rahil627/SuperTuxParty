# Spec for minigame config files.
class MinigameConfigFile:
	var name := ""
	var scene_path := ""
	var image_path: String
	var translation_directory := ""

	# BBCode (or anything that works in Richtextlabel) inside a dictionary,
	# e.g. { "en" : "English description goes here" }.
	var description := {}
	# Dictionary with { "action_name" : { ...translations...} }.
	var used_controls := {}
	var type := []

# This is the entry point filename to every minigame.
const MINIGAME_CONFIG_FILENAME = ["minigame.json", "minigame.xml"]
const MINIGAME_PATH = "res://plugins/minigames"

# Stores the full path to found minigames of each type.
var minigames_duel := []
var minigames_1v3 := []
var minigames_2v2 := []
var minigames_ffa := []

var minigames_nolok := []
var minigames_gnu := []

# Checks the directory for a minigame config file and adds its path to the
# corresonding array.
func check_directory(filename: String) -> bool:
	var new_dir := Directory.new()
	new_dir.open(filename)

	for config_file in MINIGAME_CONFIG_FILENAME:
		var complete_filename = filename + "/" + config_file
		if new_dir.file_exists(config_file):
			var config = parse_file(complete_filename)
			if config == null:
				continue

			for type in config.type:
				match type:
					"Duel":
						minigames_duel.append(complete_filename)
					"1v3":
						minigames_1v3.append(complete_filename)
					"2v2":
						minigames_2v2.append(complete_filename)
					"FFA":
						minigames_ffa.append(complete_filename)
					"Nolok":
						minigames_nolok.append(complete_filename)
					"Gnu":
						minigames_gnu.append(complete_filename)

			return true

	return false

# Checks for each file in the directory, if it is a directory and calls
# check_directory to read the config file.
func read_directory(filename: String) -> void:
	var dir := Directory.new()

	var err: int = dir.open(filename)
	if err != OK:
		print("Unable to open directory '" + filename + "'. Reason: " +
				Utility.error_code_to_string(err))
		return

	dir.list_dir_begin(true) # Parameter indicates to skip "." and "..".

	while true:
		var file: String = dir.get_next()

		if file == "":
			break
		elif dir.current_is_dir():
			if !check_directory(filename + "/" + file):
				print("Error: No config file found for minigame: " + file)

	dir.list_dir_end()

func _init() -> void:
	print("Loading minigames...")
	read_directory(MINIGAME_PATH)

	print("Loading minigames finished")
	print_loaded_minigames()

func print_loaded_minigames() -> void:
	print("Loaded minigames:")
	print("\t1v3:")
	for i in minigames_1v3:
		print("\t\t" + parse_file(i).name)
	print("\t2v2:")
	for i in minigames_2v2:
		print("\t\t" + parse_file(i).name)
	print("\tDuel:")
	for i in minigames_duel:
		print("\t\t" + parse_file(i).name)
	print("\tFFA:")
	for i in minigames_ffa:
		print("\t\t" + parse_file(i).name)
	print("\tNolok:")
	for i in minigames_nolok:
		print("\t\t" + parse_file(i).name)
	print("\tGnu:")
	for i in minigames_gnu:
		print("\t\t" + parse_file(i).name)

func parse_json_file(file: String):
	var f := File.new()
	f.open(file, File.READ)
	var result: JSONParseResult = JSON.parse(f.get_as_text())
	f.close()

	if result.error != OK:
		print("Error in file '" + file + "': " + result.error_string +
				" on line " + var2str(result.error_line))
		return

	if typeof(result.result) != TYPE_DICTIONARY:
		return

	var config := MinigameConfigFile.new()

	if not result.result.has("name"):
		print("Error in file '" + file + "': name entry missing")
		return

	config.name = result.result.name

	if not result.result.has("scene_path"):
		print("Error in file '" + file + "': scene_path entry missing")
		return

	config.scene_path = result.result.scene_path

	if not result.result.has("type"):
		print("Error in file '" + file + "': type entry missing")
		return

	config.type = result.result.type

	if result.result.has("image_path"):
		config.image_path = result.result.image_path

	if result.result.has("translation_directory"):
		config.translation_directory = result.result.translation_directory

	if result.result.has("description"):
		config.description = result.result.description
	if result.result.has("used_controls"):
		config.used_controls = result.result.used_controls

	return config

func next_element(parser, parent_element_name):
	# There is currently now do-while in gdscript :(
	if parser.read() != OK:
		return false

	while parser.get_node_type() != XMLParser.NODE_ELEMENT:
		if parser.get_node_type() == XMLParser.NODE_ELEMENT_END and parser.get_node_name() == parent_element_name:
			# The element was closed
			return false

		if parser.read() != OK:
			return false

	return true

func parse_xml_file(file: String):
	var config := MinigameConfigFile.new()

	var parser := XMLParser.new()
	parser.open(file)
	while parser.get_node_name() != "minigame":
		next_element(parser, "")

	if not parser.has_attribute("name"):
		return

	config.name = parser.get_named_attribute_value("name")

	if not parser.has_attribute("scene_path"):
		return

	config.scene_path = parser.get_named_attribute_value("scene_path")

	if not parser.has_attribute("type"):
		return

	config.type = parser.get_named_attribute_value("type").split(",", false)

	# Optional.
	if parser.has_attribute("image_path"):
		config.image_path = parser.get_named_attribute_value("image_path")

	if parser.has_attribute("translation_directory"):
		config.translation_directory =\
				parser.get_named_attribute_value("translation_directory")

	while next_element(parser, "minigame"):
		match parser.get_node_name():
			"description":
				while next_element(parser, "description"):
					var name: String = parser.get_node_name()
					parser.read()
					config.description[name] = parser.get_node_data()
			"used_controls":
				while next_element(parser, "used_controls"):
					if parser.get_node_name() != "control":
						continue

					var control_name: String =\
							parser.get_named_attribute_value("name")

					config.used_controls[control_name] = {}
					while next_element(parser, "control"):
						var language: String = parser.get_node_name()
						parser.read()
						config.used_controls[control_name][language] =\
								parser.get_node_data()

	return config

func parse_file(file: String):
	match file.get_extension():
		"json":
			return parse_json_file(file)
		"xml":
			return parse_xml_file(file)

# Utility function that should not be called use
# get_random_1v3/get_random_2v2/get_random_duel/get_random_ffa/get_random_nolok/get_random_gnu.
func _get_random_element(list: Array):
	return parse_file(list[randi() % list.size()])

func get_random_1v3():
	return _get_random_element(minigames_1v3)

func get_random_2v2():
	return _get_random_element(minigames_2v2)

func get_random_duel():
	return _get_random_element(minigames_duel)

func get_random_ffa():
	return _get_random_element(minigames_ffa)

func get_random_nolok():
	return _get_random_element(minigames_nolok)

func get_random_gnu():
	return _get_random_element(minigames_gnu)
