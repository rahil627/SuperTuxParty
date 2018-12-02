const ITEM_FILENAME = "item.gd"

const NEEDED_FILES = [ITEM_FILENAME]
const ITEM_PATH = "res://plugins/items"

# Stores the name of each subdirectory of ITEM_PATH
var items = []

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
	print("Loading items...")
	read_directory(ITEM_PATH, items)
	print("Loading items finished")

	print_loaded_items()

func print_loaded_items():
	print("Loaded items:")
	for i in items:
		print("\t" + i)

func get_loaded_items():
	return items.duplicate()

func get_item_path(name):
	return ITEM_PATH + "/" + name + "/" + ITEM_FILENAME
