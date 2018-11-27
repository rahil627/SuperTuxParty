const SAVEGAME_DIRECTORY = "user://saves/"

class SaveGamePlayerState:
	var player_name = ""
	var is_ai = false
	var space = ""
	var character = ""
	var cookies = 0
	var cakes = 0
	
	var items = []

class SaveGame:
	var name = ""
	var players = [SaveGamePlayerState.new(), SaveGamePlayerState.new(), SaveGamePlayerState.new(), SaveGamePlayerState.new()]
	
	var current_minigame = null
	
	var board_path = ""
	var cookie_space = 0
	var player_turn = 1
	var award_type = Global.AWARD_T.linear
	
	var trap_states = []

var savegames

func read_savegames():
	savegames = []
	
	var dir = Directory.new()
	if dir.open(SAVEGAME_DIRECTORY) != OK:
		return
	
	dir.list_dir_begin(true)
	
	while true:
		var filename = dir.get_next()
		
		if filename == "":
			break
		
		var file = File.new()
		var err = file.open(SAVEGAME_DIRECTORY + filename, File.READ)
		if err != OK:
			print("Couldn't open file '%s'" % (SAVEGAME_DIRECTORY + filename))
			continue
		
		var savegame = parse_json(file.get_as_text())
		if typeof(savegame) != TYPE_DICTIONARY:
			print("File '%s' is not a valid save" % (SAVEGAME_DIRECTORY + filename))
			continue
		
		file.close()
		
		savegame = dict2inst(savegame)
		savegames.append(savegame)
		
		for i in range(savegame.players.size()):
			savegame.players[i] = dict2inst(savegame.players[i])
	
	dir.list_dir_end()

func get_num_savegames():
	return savegames.size()

func get_savegame(i):
	return savegames[i]

# Returns true on success
func save(savegame):
	if not savegames.has(savegame):
		savegames.append(savegame)
	
	var directory = Directory.new()
	if not directory.dir_exists(SAVEGAME_DIRECTORY):
		var err = directory.make_dir_recursive(SAVEGAME_DIRECTORY)
		if err != OK:
			print("Failed to create directory '%s'" % SAVEGAME_DIRECTORY)
			return false
	
	var file = File.new()
	var filename = SAVEGAME_DIRECTORY + savegame.name
	var err = file.open(filename, File.WRITE)
	if err != OK:
		print("Failed to open file '%s'" % filename)
		return false
	
	var save_dict = inst2dict(savegame)
	
	# 'inst2dict()' is not recursive. Serialize the players.
	var players_serialized = []
	for i in savegame.players.size():
		players_serialized.append(inst2dict(savegame.players[i]))
	save_dict["players"] = players_serialized
	
	file.store_string(to_json(save_dict))
	file.close()
	
	# Sync the savegames
	read_savegames()
	return true

func delete_savegame(savegame):
	if not savegames.has(savegame):
		return
	
	savegames.erase(savegame)
	
	var directory = Directory.new()
	var err = directory.remove(SAVEGAME_DIRECTORY + savegame.name)
	if err != OK:
		print("Failed to delete file '%s'" % SAVEGAME_DIRECTORY + savegame.name)
