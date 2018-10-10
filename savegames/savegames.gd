const SAVEGAME_DIRECTORY = "user://saves/"

class SaveGamePlayerState:
	var player_name = ""
	var is_ai = false
	var space = ""
	var character = ""
	var cookies = 0
	var cakes = 0

class SaveGame:
	var name = ""
	var players = [SaveGamePlayerState.new(), SaveGamePlayerState.new(), SaveGamePlayerState.new(), SaveGamePlayerState.new()]
	
	var current_minigame = null
	
	var board_path = ""
	var cookie_space = 0
	var player_turn = 1
	var award_type = Global.AWARD_T.linear

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
	
	var result
	
	# inst2dict is not recursive => first serialize the players
	for i in range(savegame.players.size()):
		savegame.players[i] = inst2dict(savegame.players[i])
	result = inst2dict(savegame)
	
	file.store_string(to_json(result))
	file.close()
	
	# Sync the savegames
	read_savegames()
	return true
