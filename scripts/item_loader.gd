const NEEDED_FILES = ["item.gd", "item.gdc"]
const ITEM_PATH = "res://plugins/items"

# Stores the path to each item.gd file of each subdirectory of ITEM_PATH
var items = []

var buyable_items = []

# Checks if one of the filenames in 'files' exists in directory filename + "/" + file
func exist_files(filename, file, files):
	var new_dir = Directory.new()
	new_dir.open(filename + "/" + file)
	for f in files:
		if new_dir.file_exists(f):
			return f
	
	print("Error: No file of %s found for: %s" % [NEEDED_FILES, file])
	return false

# checks every file in the directory given by filename and adds every path to a MINIGAME_BOARD_FILENAME file of each directory into the output array
func read_directory(filename, output, buyable):
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
			var path = exist_files(filename, file, NEEDED_FILES)
			if path:
				output.append(file + "/" + path)
				
				var fullpath = filename + "/" + file + "/" + path
				if load(fullpath).new().can_be_bought:
					buyable.append(file + "/" + path)

	dir.list_dir_end()

func _init():
	print("Loading items...")
	read_directory(ITEM_PATH, items, buyable_items)
	print("Loading items finished")

	print_loaded_items()

func print_loaded_items():
	print("Loaded items:")
	for i in items:
		print("\t" + i)

func get_loaded_items():
	return items.duplicate()

func get_buyable_items():
	return buyable_items.duplicate()

func get_item_path(name):
	var path = ITEM_PATH + "/" + name
	
	return path
