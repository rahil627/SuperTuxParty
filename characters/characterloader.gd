const CHARACTER_FILENAME = "character.tscn"
const CHARACTER_SPLASHNAME = "splash.png"
const MATERIAL_FILENAME = "material.tres"
const COLLISION_SHAPE_FILENAME = "collision.tres"

const NEEDED_FILES = [CHARACTER_FILENAME, CHARACTER_SPLASHNAME]
const CHARACTER_PATH = "res://characters"

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
		# TODO convert error code to error string
		print("Unable to open directory '" + filename + "'. Debug error code: " + String(err))
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

# TODO: make output pretty
func print_loaded_characters():
	print("Loaded characters:")
	print(characters)

func get_loaded_characters():
	return characters

func get_character_path(name):
	return CHARACTER_PATH + "/" + name + "/" + CHARACTER_FILENAME

func get_material_path(name):
	return CHARACTER_PATH + "/" + name + "/" + MATERIAL_FILENAME

func get_character_splash(name):
	return CHARACTER_PATH + "/" + name + "/" + CHARACTER_SPLASHNAME

func get_collision_shape_path(name):
	return CHARACTER_PATH + "/" + name + "/" + COLLISION_SHAPE_FILENAME