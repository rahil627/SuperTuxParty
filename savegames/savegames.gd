class_name SaveGameLoader

const SAVEGAME_DIRECTORY = "user://saves/"

class SaveGamePlayerState:
	var player_name := ""
	var is_ai := false
	var space: NodePath
	var character := ""
	var cookies := 0
	var cakes := 0

	var items := []

class SaveGame:
	var name := ""
	var players := [SaveGamePlayerState.new(), SaveGamePlayerState.new(),
			SaveGamePlayerState.new(), SaveGamePlayerState.new()]

	var current_minigame

	var board_path: = ""
	var cake_space := 0
	var player_turn := 1
	var cake_cost := 30
	var max_turns := 10
	var award_type: int = Global.AWARD_TYPE.LINEAR

	var trap_states := []

var savegames: Array

func read_savegames() -> void:
	savegames.clear()

	var dir := Directory.new()
	if dir.open(SAVEGAME_DIRECTORY) != OK:
		return

	dir.list_dir_begin(true)

	while true:
		var filename: String = dir.get_next()

		if filename == "":
			break

		var file := File.new()
		var err: int = file.open(SAVEGAME_DIRECTORY + filename, File.READ)
		if err != OK:
			print("Couldn't open file '%s'" % (SAVEGAME_DIRECTORY + filename))
			continue

		var savegame_var = parse_json(file.get_as_text())
		if typeof(savegame_var) != TYPE_DICTIONARY:
			print("File '%s' is not a valid save" %
					(SAVEGAME_DIRECTORY + filename))
			continue

		file.close()

		var savegame = dict2inst(savegame_var)
		if not savegame is SaveGame:
			print("File '%s' is not a valid save" %
					(SAVEGAME_DIRECTORY + filename))
			continue

		savegames.append(savegame)

		for i in savegame.players.size():
			savegame.players[i] = dict2inst(savegame.players[i])

	dir.list_dir_end()

func get_num_savegames() -> int:
	return savegames.size()

func get_savegame(i) -> SaveGame:
	return savegames[i]

# Returns true on success.
func save(savegame: SaveGame) -> bool:
	if not savegames.has(savegame):
		savegames.append(savegame)

	var dir := Directory.new()
	if not dir.dir_exists(SAVEGAME_DIRECTORY):
		var err: int = dir.make_dir_recursive(SAVEGAME_DIRECTORY)
		if err != OK:
			print("Failed to create directory '%s'" % SAVEGAME_DIRECTORY)
			return false

	var file := File.new()
	var filename: String = SAVEGAME_DIRECTORY + savegame.name
	var err: int = file.open(filename, File.WRITE)
	if err != OK:
		print("Failed to open file '%s'" % filename)
		return false

	var save_dict: Dictionary = inst2dict(savegame)

	# 'inst2dict()' is not recursive. Serialize the players.
	var players_serialized := []
	for i in savegame.players.size():
		players_serialized.append(inst2dict(savegame.players[i]))
	save_dict["players"] = players_serialized

	file.store_string(to_json(save_dict))
	file.close()

	# Sync the savegames.
	read_savegames()
	return true

func delete_savegame(savegame: SaveGame) -> void:
	if not savegames.has(savegame):
		return

	savegames.erase(savegame)

	var directory := Directory.new()
	var err: int = directory.remove(SAVEGAME_DIRECTORY + savegame.name)
	if err != OK:
		print("Failed to delete file '%s'" % SAVEGAME_DIRECTORY + savegame.name)
