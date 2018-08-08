var global

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

func read_directory(filename, output):
	var dir = Directory.new()
	dir.open(filename)
	dir.list_dir_begin()
	
	while true:
		var file = dir.get_next()
		
		if file == "." or file == "..":
			continue
		
		if file == "":
			break
		elif dir.current_is_dir():
			var newDir = Directory.new()
			newDir.open(filename + "/" + file)
			if newDir.file_exists(MINIGAME_BOARD_FILENAME):
				output.append(filename + "/" + file + "/" + MINIGAME_BOARD_FILENAME)
			else:
				print("Error: No '" + MINIGAME_BOARD_FILENAME + "' file found for: " + file)
	
	dir.list_dir_end()

func _init(g):
	global = g
	read_directory(MINIGAME_1v3_PATH,  minigames_1v3)
	read_directory(MINIGAME_2v2_PATH,  minigames_2v2)
	read_directory(MINIGAME_DUEL_PATH, minigames_duel)
	read_directory(MINIGAME_FFA_PATH,  minigames_ffa)

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