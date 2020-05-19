# This is the entry point filename to every minigame.
const BOARD_FILENAME := "board.tscn"
const BOARD_PATH := "res://plugins/boards"

# Stores the name of each subdirectory of BOARD_PATH.
var boards := []

func discover_board(filename: String):
	boards.append(filename.split('/')[-2])

func _init() -> void:
	print("Loading boards...")
	PluginSystem.load_files_from_path(BOARD_PATH, [ BOARD_FILENAME ], self, "discover_board")
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
