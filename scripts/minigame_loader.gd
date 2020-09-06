# Spec for minigame config files.
class MinigameConfigFile:
	var filename := ""

	var name := ""
	var scene_path := ""
	var image_path: String
	var translation_directory := ""

	# BBCode (or anything that works in Richtextlabel) inside a dictionary,
	# e.g. { "en" : "English description goes here" }.
	# Or a plain string, which will be the description for every language
	var description = ""
	# Dictionary with { "action_name" : { ...translations...} }.
	var controls := {}
	var type := []

# This is the entry point filename to every minigame.
const MINIGAME_CONFIG_FILENAME := [ "minigame.json" ]
const MINIGAME_PATH := "res://plugins/minigames"

var minigames := []
var played := []

func discover_minigame(complete_filename: String):
	var config = parse_file(complete_filename)
	if not config:
		return
	
	minigames.push_back(config)

func _init() -> void:
	print("Loading minigames...")
	PluginSystem.load_files_from_path(MINIGAME_PATH, MINIGAME_CONFIG_FILENAME,
			self, "discover_minigame")

	print("Loading minigames finished")
	print_loaded_minigames()
	minigames.shuffle()

func print_loaded_minigames() -> void:
	print("Loaded minigames:")
	print("\t1v3:")
	for minigame in minigames:
		if "1v3" in minigame.type:
			print("\t\t" + minigame.filename.split("/")[-2])
	print("\t2v2:")
	for minigame in minigames:
		if "2v2" in minigame.type:
			print("\t\t" + minigame.filename.split("/")[-2])
	print("\tDuel:")
	for minigame in minigames:
		if "Duel" in minigame.type:
			print("\t\t" + minigame.filename.split("/")[-2])
	print("\tFFA:")
	for minigame in minigames:
		if "FFA" in minigame.type:
			print("\t\t" + minigame.filename.split("/")[-2])
	print("\tNolok Solo:")
	for minigame in minigames:
		if "NolokSolo" in minigame.type:
			print("\t\t" + minigame.filename.split("/")[-2])
	print("\tNolok Coop:")
	for minigame in minigames:
		if "NolokCoop" in minigame.type:
			print("\t\t" + minigame.filename.split("/")[-2])
	print("\tGnu Solo:")
	for minigame in minigames:
		if "GnuSolo" in minigame.type:
			print("\t\t" + minigame.filename.split("/")[-2])
	print("\tGnu Coop:")
	for minigame in minigames:
		if "GnuCoop" in minigame.type:
			print("\t\t" + minigame.filename.split("/")[-2])

func parse_file(file: String) -> MinigameConfigFile:
	var f := File.new()
	f.open(file, File.READ)
	var result: JSONParseResult = JSON.parse(f.get_as_text())
	f.close()

	if result.error != OK:
		push_error("Error in file '{0}': {1} on line {2}".format([file,
				result.error_string, result.error_line]))
		return null

	if not result.result is Dictionary:
		push_error("Error in file '{0}': content type is not a dictionary".format([file]))
		return null

	var config := MinigameConfigFile.new()
	config.filename = file

	if not result.result.has("name"):
		push_error("Error in file '{0}': entry 'name' missing".format([file]))
		return null
	
	if not (result.result.name is String or result.result.name is Dictionary):
		push_error("Error in file '{0}': entry 'name' is not a String" +
				" or dictionary".format([file]))
		return null

	config.name = result.result.name

	if not result.result.has("scene_path"):
		push_error("Error in file '{0}': entry 'scene_path' missing".format([
					file]))
		return null

	if not result.result.scene_path is String:
		push_error("Error in file '{0}': entry 'scene_path'" +
				" is not of type String".format([file]))
		return null
	config.scene_path = result.result.scene_path

	if not result.result.has("type"):
		push_error("Error in file '{0}': entry 'type' missing".format([file]))
		return null

	config.type = result.result.type

	if result.result.has("image_path"):
		if result.result.image_path is String:
			config.image_path = result.result.image_path
		else:
			push_error("Error in file '{0}': entry 'image_path'" +
					" is not of type String".format([file]))

	if result.result.has("translation_directory"):
		var translation_directory = result.result.translation_directory
		if translation_directory is String:
			config.translation_directory = translation_directory
		else:
			push_error("Error in file '{0}': entry 'translation_directory'" +
					" is not a String. Ignoring".format([file]))

	if result.result.has("description"):
		var description = result.result.description
		if description is String or description is Dictionary:
			config.description = description
		else:
			push_error("Error in file '{0}': entry 'description'" +
					" is neither a String nor a dictionary. Ignoring".format([
						file]))

	if result.result.has("controls"):
		var controls = result.result.controls
		if controls is Dictionary:
			var valid = true
			for key in controls.keys():
				var value = controls[key]
				if not key is String:
					valid = false
					push_error("Error in file '{0} in entry 'controls':" + 
							" dictionary key '{1}' is not a string".format([
								file, str(key)]))
				if not value is String:
					valid = false
					push_error("Error in file '{0}' in entry 'controls':" +
							" dictionary value '{1}' is not a string".format([
								file, str(value)]))
			if valid:
				config.controls = result.result.controls
		else:
			push_error("Error in file '{0}': entry 'controls'" +
					" is not a dictionary".format([file]))
	return config

# Utility function that should not be called use
# get_random_1v3/get_random_2v2/get_random_duel/get_random_ffa/get_random_nolok/get_random_gnu.
func _get_random_minigame(type: String):
	for i in range(len(minigames)):
		if type in minigames[i].type:
			var minigame = minigames[i]
			minigames.remove(i)
			played.append(minigame)
			return minigame
	# There's no minigame that has the needed type
	# If we're at the start of the queue, then there's no minigame of that type,
	# because we just looked at all of them
	assert(len(played) > 0, "No minigame for type: " + type)
	# Rebuild a new queue, but keep the unused elements at the start
	played.shuffle()
	minigames += played
	played = []
	return _get_random_minigame(type)

func get_random_1v3():
	return _get_random_minigame("1v3")

func get_random_2v2():
	return _get_random_minigame("2v2")

func get_random_duel():
	return _get_random_minigame("Duel")

func get_random_ffa():
	return _get_random_minigame("FFA")

func get_random_nolok_solo():
	return _get_random_minigame("NolokSolo")

func get_random_nolok_coop():
	return _get_random_minigame("NolokCoop")

func get_random_gnu_solo():
	return _get_random_minigame("GnuSolo")

func get_random_gnu_coop():
	return _get_random_minigame("GnuCoop")
