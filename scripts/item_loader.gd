const NEEDED_FILES = ["item.gd", "item.gdc"]
const ITEM_PATH = "res://plugins/items"

# Stores the path to each item.gd file of each subdirectory of ITEM_PATH.
var items := []

var buyable_items := []

# Checks if one of the filenames in 'files' exists in directory
# filename + "/" + file.
func exist_files(filename: String, file: String, files: Array) -> String:
	var new_dir := Directory.new()
	new_dir.open(filename + "/" + file)
	for f in files:
		if new_dir.file_exists(f):
			return f

	print("Error: No file of %s found for: %s" % [NEEDED_FILES, file])
	return ""

# Checks every file in the directory given by filename and adds every path to a
# MINIGAME_BOARD_FILENAME file of each directory into the output array.
func read_directory(filename: String, output: Array, buyable: Array) -> void:
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
			var path: String = exist_files(filename, file, NEEDED_FILES)
			if path != "":
				output.append(file + "/" + path)

				var fullpath: String = filename + "/" + file + "/" + path
				if load(fullpath).new().can_be_bought:
					buyable.append(file + "/" + path)

	dir.list_dir_end()

func _init() -> void:
	print("Loading items...")
	read_directory(ITEM_PATH, items, buyable_items)
	print("Loading items finished")

	print_loaded_items()

func print_loaded_items() -> void:
	print("Loaded items:")
	for i in items:
		print("\t" + i)

func get_loaded_items() -> Array:
	return items.duplicate()

func get_buyable_items() -> Array:
	return buyable_items.duplicate()

func get_item_path(name: String) -> String:
	var path = ITEM_PATH + "/" + name

	return path
