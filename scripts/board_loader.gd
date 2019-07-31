# This is the entry point filename to every minigame.
const BOARD_FILENAME = "board.tscn"
const BOARD_PATH = "res://plugins/boards"

# Stores the name of each subdirectory of BOARD_PATH.
var boards := []

# Checks every file in the directory given by filename and adds every path to a
# MINIGAME_BOARD_FILENAME file of each directory into the output array.
func read_directory(filename: String, output: Array) -> void:
	var dir := Directory.new()

	var err: int = dir.open(filename)
	if err != OK:
		# TODO: convert error code to error string.
		print("Unable to open directory '" + filename + "'. Reason: " +
				Utility.error_code_to_string(err))
		return
	dir.list_dir_begin(true) # Parameter indicates to skip "." and "..".

	while true:
		var file: String = dir.get_next()

		if file == "":
			break
		elif dir.current_is_dir():
			var new_dir := Directory.new()
			new_dir.open(filename + "/" + file)
			if new_dir.file_exists(BOARD_FILENAME):
				output.append(file)
			else:
				print("Error: No '" + BOARD_FILENAME + "' file found for: " +
						file)

	dir.list_dir_end()

func _init() -> void:
	print("Loading boards...")
	read_directory(BOARD_PATH,  boards)
	print("Loading boards finished")

	print_loaded_boards()

# TODO: make output pretty.
func print_loaded_boards() -> void:
	print("Loaded boards:")
	for i in boards:
		print("\t" + i)

func get_loaded_boards() -> Array:
	return boards

func get_board_path(name: String) -> String:
	return BOARD_PATH + "/" + name + "/" + BOARD_FILENAME
