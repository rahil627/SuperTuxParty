const CHARACTER_FILENAME = "character.tscn"
const CHARACTER_SPLASHNAME = "splash.png"

const NEEDED_FILES = [CHARACTER_FILENAME]
const CHARACTER_PATH = "res://plugins/characters"

# Stores the name of each subdirectory of CHARACTER_PATH
var characters = []

# Checks if every file f in files exists in directory filename + "/" + file
func exist_all_files(filename, file, files):
	var new_dir = Directory.new()
	new_dir.open(filename + "/" + file)
	for f in files:
		if not new_dir.file_exists(f):
			print("Error: No '" + f + "' file found for: " + file)
			return false
	
	return true

# checks every file in the directory given by filename and adds every path to a MINIGAME_BOARD_FILENAME file of each directory into the output array
func read_directory(filename, output):
	var dir = Directory.new()
	
	var err = dir.open(filename)
	if(err != OK):
		print("Unable to open directory '" + filename + "'. Reason: " + Utility.error_code_to_string(err))
		return
	
	dir.list_dir_begin(true) # Parameter indicates to skip . and ..
	
	while true:
		var file = dir.get_next()
		
		if file == "":
			break
		elif dir.current_is_dir():
			if exist_all_files(filename, file, NEEDED_FILES):
				output.append(file)

	
	dir.list_dir_end()

func _init():
	print("Loading characters...")
	read_directory(CHARACTER_PATH,  characters)
	print("Loading characters finished")
	
	print_loaded_characters()

func print_loaded_characters() -> void:
	print("Loaded characters:")
	for i in characters:
		print("\t" + i)

func get_loaded_characters() -> Array:
	return characters.duplicate()

func load_character(name: String) -> Spatial:
	return load(CHARACTER_PATH + "/" + name + "/" + CHARACTER_FILENAME).instance()

func load_character_splash(name) -> Resource:
	return load(CHARACTER_PATH + "/" + name + "/" + CHARACTER_SPLASHNAME)
