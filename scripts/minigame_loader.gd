# Spec for minigame config files.
class MinigameConfigFile:
	var file := ""

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

# Stores the full path to found minigames of each type.
var minigames_duel := []
var minigames_1v3 := []
var minigames_2v2 := []
var minigames_ffa := []

var minigames_nolok_solo := []
var minigames_nolok_coop := []
var minigames_gnu_solo := []
var minigames_gnu_coop := []

func discover_minigame(complete_filename: String):
	var config = parse_file(complete_filename)
	if not config:
		return

	for type in config.type:
		match type:
			"Duel":
				minigames_duel.append(complete_filename)
			"1v3":
				minigames_1v3.append(complete_filename)
			"2v2":
				minigames_2v2.append(complete_filename)
			"FFA":
				minigames_ffa.append(complete_filename)
			"NolokSolo":
				minigames_nolok_solo.append(complete_filename)
			"NolokCoop":
				minigames_nolok_coop.append(complete_filename)
			"GnuSolo":
				minigames_gnu_solo.append(complete_filename)
			"GnuCoop":
				minigames_gnu_coop.append(complete_filename)
			_:
				push_warning("Unknown minigame type: '" + type + "'")

	return true

func _init() -> void:
	print("Loading minigames...")
	PluginSystem.load_files_from_path(MINIGAME_PATH, MINIGAME_CONFIG_FILENAME,
			self, "discover_minigame")

	print("Loading minigames finished")
	print_loaded_minigames()

func print_loaded_minigames() -> void:
	print("Loaded minigames:")
	print("\t1v3:")
	for i in minigames_1v3:
		print("\t\t" + parse_file(i).name)
	print("\t2v2:")
	for i in minigames_2v2:
		print("\t\t" + parse_file(i).name)
	print("\tDuel:")
	for i in minigames_duel:
		print("\t\t" + parse_file(i).name)
	print("\tFFA:")
	for i in minigames_ffa:
		print("\t\t" + parse_file(i).name)
	print("\tNolok Solo:")
	for i in minigames_nolok_solo:
		print("\t\t" + parse_file(i).name)
	print("\tNolok Coop:")
	for i in minigames_nolok_coop:
		print("\t\t" + parse_file(i).name)
	print("\tGnu Solo:")
	for i in minigames_gnu_solo:
		print("\t\t" + parse_file(i).name)
	print("\tGnu Coop:")
	for i in minigames_gnu_coop:
		print("\t\t" + parse_file(i).name)

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
	config.file = file

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
func _get_random_element(list: Array):
	return parse_file(list[randi() % list.size()])

func get_random_1v3():
	return _get_random_element(minigames_1v3)

func get_random_2v2():
	return _get_random_element(minigames_2v2)

func get_random_duel():
	return _get_random_element(minigames_duel)

func get_random_ffa():
	return _get_random_element(minigames_ffa)

func get_random_nolok_solo():
	return _get_random_element(minigames_nolok_solo)

func get_random_nolok_coop():
	return _get_random_element(minigames_nolok_coop)

func get_random_gnu_solo():
	return _get_random_element(minigames_gnu_solo)

func get_random_gnu_coop():
	return _get_random_element(minigames_gnu_coop)
