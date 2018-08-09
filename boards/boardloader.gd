# This is the entry point filename to every minigame
const BOARD_FILENAME = "board.tscn"
const BOARD_PATH = "res://boards"

# Stores the name of each subdirectory of BOARD_PATH
var boards = []

# checks every file in the directory given by filename and adds every path to a MINIGAME_BOARD_FILENAME file of each directory into the output array
func read_directory(filename, output):
	var dir = Directory.new()
	
	var err = dir.open(filename)
	if(err != OK):
		# I don't know how to convert an error code to a string and can't find anything online...
		# FIXME
		print("Unable to open directory '" + filename + "'. Reason: " + String(err))
		return
	dir.list_dir_begin(true) # Parameter indicates to skip . and ..
	
	while true:
		var file = dir.get_next()
		
		if file == "":
			break
		elif dir.current_is_dir():
			var new_dir = Directory.new()
			new_dir.open(filename + "/" + file)
			if new_dir.file_exists(BOARD_FILENAME):
				output.append(file)
			else:
				print("Error: No '" + BOARD_FILENAME + "' file found for: " + file)
	
	dir.list_dir_end()

func _init():
	print("Loading boards...")
	read_directory(BOARD_PATH,  boards)
	print("Loading boards finished")
	
	print_loaded_boards()

# TODO: make output pretty
func print_loaded_boards():
	print("Loaded boards:")
	print(boards)

func get_loaded_boards():
	return boards

func get_board_path(name):
	return BOARD_PATH + "/" + name + "/" + BOARD_FILENAME
