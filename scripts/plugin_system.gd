extends Node

# The directory from which plugins are loaded. Plugins have to be either in
# .zip or .pck file format.
const PLUGIN_DIRECTORY := "plugins"

onready var board_loader = preload("res://scripts/board_loader.gd").new()
onready var minigame_loader = preload("res://scripts/minigame_loader.gd").new()
onready var character_loader = preload("res://scripts/character_loader.gd").new()
onready var item_loader = preload("res://scripts/item_loader.gd").new()

func load_files_from_path(path: String, filename: Array, object: Object,
		method: String):
	var dir := Directory.new()

	var err: int = dir.open(path)
	if err != OK:
		print("Unable to open directory '{0}'. Reason: {1}".format([path, 
				Utility.error_code_to_string(err)]))
		return

	dir.list_dir_begin(true) # Parameter indicates to skip "." and "..".

	while true:
		var entry: String = dir.get_next()

		if entry == "":
			break
		elif dir.current_is_dir():
			for file in filename:
				if dir.file_exists(path + "/" + entry + "/" + file):
					object.call(method, path + "/" + entry + "/" + file)

	dir.list_dir_end()

# Loads all .pck and .zip files into the res:// file system.
func read_content_packs() -> void:
	var dir := Directory.new()
	var err: int = dir.open(PLUGIN_DIRECTORY)
	if err != OK:
		print("Unable to open directory '{0}'. Reason: {1}".format([
				PLUGIN_DIRECTORY, Utility.error_code_to_string((err))]))
		return
	dir.list_dir_begin(true) # Parameter indicates to skip "." and "..".

	while true:
		var file: String = dir.get_next()

		if file == "":
			break
		elif not dir.current_is_dir() and (file.ends_with(".pck") or\
				file.ends_with(".zip")):
			if ProjectSettings.load_resource_pack(
					PLUGIN_DIRECTORY + "/" + file, true):
				print("Successfully loaded plugin: " + file)
			else:
				print("Error while loading plugin: " + file)
		elif not dir.current_is_dir():
			print("Failed to load plugin: '{0}' is neither a .pck" + \
					" nor a .zip file".format([file]))
	dir.list_dir_end()

func _init() -> void:
	# Only use files present in the project, no external files.
	# Useful for testing.
	if not OS.is_debug_build() or ProjectSettings.get("plugins/load_plugins"):
		print("Loading plugins...")
		read_content_packs()
		print("Loading plugins finished")
