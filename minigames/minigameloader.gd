var global

# The directory from which plugins are loaded. Plugins have to be either in .zip or .pck file format
const PLUGIN_DIRECTORY = "plugins"

# This is the entry point filename to every minigame
const MINIGAME_BOARD_FILENAME = "minigame.tscn"
const MINIGAME_1v3_PATH  = "res://minigames/1v3"
const MINIGAME_2v2_PATH  = "res://minigames/2v2"
const MINIGAME_DUEL_PATH = "res://minigames/Duel"
const MINIGAME_FFA_PATH  = "res://minigames/FFA"

# Stores the full path to found minigames of each type
var minigames_duel = []
var minigames_1v3  = []
var minigames_2v2  = []
var minigames_ffa  = []

# loads all .pck and .zip files into the res:// file system
# Maybe if we add other types of plugins, we should move this out of here in a more general place
func read_content_packs():
	var dir = Directory.new()
	dir.open(PLUGIN_DIRECTORY)
	dir.list_dir_begin(true) # Parameter indicates to skip . and ..
	
	while true:
		var file = dir.get_next()
		
		if file == "":
			break
		elif not dir.current_is_dir() and (file.ends_with(".pck") or file.ends_with(".zip")):
			if(ProjectSettings.load_resource_pack(PLUGIN_DIRECTORY + "/" + file)):
				print("Successfully loaded plugin: " + file)
			else:
				print("Error while loading plugin: " + file)
		elif not dir.current_is_dir():
			print("Failed to load plugin: " + file + " is neither a .pck nor a .zip file")
	
	dir.list_dir_end()

# checks every file in the directory given by filename and adds every path to a MINIGAME_BOARD_FILENAME file of each directory into the output array
func read_directory(filename, output):
	var dir = Directory.new()
	dir.open(filename)
	dir.list_dir_begin(true) # Parameter indicates to skip . and ..
	
	while true:
		var file = dir.get_next()
		
		if file == "":
			break
		elif dir.current_is_dir():
			var new_dir = Directory.new()
			new_dir.open(filename + "/" + file)
			if new_dir.file_exists(MINIGAME_BOARD_FILENAME):
				output.append(filename + "/" + file + "/" + MINIGAME_BOARD_FILENAME)
			else:
				print("Error: No '" + MINIGAME_BOARD_FILENAME + "' file found for: " + file)
	
	dir.list_dir_end()

func _init(g):
	global = g
	
	read_content_packs()
	
	read_directory(MINIGAME_1v3_PATH,  minigames_1v3)
	read_directory(MINIGAME_2v2_PATH,  minigames_2v2)
	read_directory(MINIGAME_DUEL_PATH, minigames_duel)
	read_directory(MINIGAME_FFA_PATH,  minigames_ffa)
	
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

# Utility function that should not be called use
# goto_random_1v3/goto_random_2v2/goto_random_duel/goto_random_ffa
func _goto_random_element(list):
	# Should a minigame be removed if it was already played?
	global.goto_scene(list[randi()%list.size()])

func goto_random_1v3():
	_goto_random_element(minigames_1v3)

func goto_random_2v2():
	_goto_random_element(minigames_2v2)

func goto_random_duel():
	_goto_random_element(minigames_duel)

func goto_random_ffa():
	_goto_random_element(minigames_ffa)
