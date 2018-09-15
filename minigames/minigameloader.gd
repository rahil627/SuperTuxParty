var global

# Spec for minigame config files
class MinigameConfigFile:
	var name = ""
	var scene_path = ""
	var image_path = null
	
	# BBCode (or anything that works in Richtextlabel) inside a dictionary, e.g. { "en" : "English description goes here" }
	var description = {}
	# Dictionary with { "action_name" : { ...translations...} }
	var used_controls = {}

# This is the entry point filename to every minigame
const MINIGAME_CONFIG_FILENAME = ["minigame.json", "minigame.xml"]
const MINIGAME_1v3_PATH  = "res://minigames/1v3"
const MINIGAME_2v2_PATH  = "res://minigames/2v2"
const MINIGAME_DUEL_PATH = "res://minigames/Duel"
const MINIGAME_FFA_PATH  = "res://minigames/FFA"

# Stores the full path to found minigames of each type
var minigames_duel = []
var minigames_1v3  = []
var minigames_2v2  = []
var minigames_ffa  = []

# Checks a directory if a config file can be found and adds its path to output
func check_directory(filename, output):
	var new_dir = Directory.new()
	new_dir.open(filename )
	
	for config_file in MINIGAME_CONFIG_FILENAME:
		var complete_filename = filename + "/" + config_file
		if new_dir.file_exists(config_file) and parse_file(complete_filename) != null:
			output.append(complete_filename)
			return true
	
	return false

# checks every file in the directory given by filename and adds every path to a MINIGAME_BOARD_FILENAME file of each directory into the output array
func read_directory(filename, output):
	var dir = Directory.new()
	
	var err = dir.open(filename)
	if(err != OK):
		# TODO convert error code to error string
		print("Unable to open directory '" + filename + "'. Debug error code: " + String(err))
		return

	dir.list_dir_begin(true) # Parameter indicates to skip . and ..
	
	while true:
		var file = dir.get_next()
		
		if file == "":
			break
		elif dir.current_is_dir():
			if !check_directory(filename + "/" + file, output):
				print("Error: No config file found for minigame: " + file)
	
	dir.list_dir_end()

func _init(g):
	global = g
	
	print("Loading minigames...")
	read_directory(MINIGAME_1v3_PATH,  minigames_1v3)
	read_directory(MINIGAME_2v2_PATH,  minigames_2v2)
	read_directory(MINIGAME_DUEL_PATH, minigames_duel)
	read_directory(MINIGAME_FFA_PATH,  minigames_ffa)
	
	print("Loading minigames finished")
	print_loaded_minigames()

# TODO: make output pretty
func print_loaded_minigames():
	print("Loaded minigames:")
	print("1v3:")
	print(minigames_1v3)
	print("2v2:")
	print(minigames_2v2)
	print("Duel:")
	print(minigames_duel)
	print("FFA:")
	print(minigames_ffa)

func parse_json_file(file):
	var f = File.new()
	f.open(file, File.READ)
	var result = JSON.parse(f.get_as_text())
	f.close()
	
	if(result.error != OK):
		print("Error in file '" + file + "': " + result.error_string + " on line " + var2str(result.error_line))
		return null
	
	if typeof(result.result) != TYPE_DICTIONARY:
		return null
	
	var config = MinigameConfigFile.new()
	
	if !result.result.has("name"):
		return null
	
	config.name = result.result.name
	
	if !result.result.has("scene_path"):
		return null
	
	config.scene_path = result.result.scene_path
	
	if result.result.has("image_path"):
		config.image_path = result.result.image_path
	
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

func parse_xml_file(file):
	var config = MinigameConfigFile.new()
	
	var parser = XMLParser.new()
	parser.open(file)
	while parser.get_node_name() != "minigame":
		next_element(parser, "")
	
	if !parser.has_attribute("name"):
		return null
	
	config.name = parser.get_named_attribute_value("name")
	
	if !parser.has_attribute("scene_path"):
		return null
	
	config.scene_path = parser.get_named_attribute_value("scene_path")
	
	# Optional
	if parser.has_attribute("image_path"):
		config.image_path = parser.get_named_attribute_value("image_path")
	
	while next_element(parser, "minigame"):
		match parser.get_node_name():
			"description":
				while next_element(parser, "description"):
					var name = parser.get_node_name()
					parser.read()
					config.description[name] = parser.get_node_data()
			"used_controls":
				while next_element(parser, "used_controls"):
					if parser.get_node_name() != "control":
						continue
					
					var control_name = parser.get_named_attribute_value("name")
					
					config.used_controls[control_name] = {}
					next_element(parser, "control")
					var language = parser.get_node_name()
					parser.read()
					config.used_controls[control_name][language] = parser.get_node_data()
	
	return config

func parse_file(file):
	match file.get_extension():
		"json":
			return parse_json_file(file)
		"xml":
			return parse_xml_file(file)

# Utility function that should not be called use
# get_random_1v3/get_random_2v2/get_random_duel/get_random_ffa
func _get_random_element(list):
	return parse_file(list[randi()%list.size()])

func get_random_1v3():
	return _get_random_element(minigames_1v3)

func get_random_2v2():
	return _get_random_element(minigames_2v2)

func get_random_duel():
	return _get_random_element(minigames_duel)

func get_random_ffa():
	return _get_random_element(minigames_ffa)
