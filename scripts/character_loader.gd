const CHARACTER_FILENAME := "character.tscn"
const CHARACTER_SPLASHNAME := "splash.png"

const NEEDED_FILES := [ CHARACTER_FILENAME ]
const CHARACTER_PATH := "res://plugins/characters"

# Stores the name of each subdirectory of CHARACTER_PATH
var characters := []

func discover_character(filename: String) -> void:
	# Get the second last path entry
	# e.g. res://plugins/characters/Tux/character.tscn -> Tux
	characters.append(filename.split('/')[-2])

func _init():
	print("Loading characters...")
	PluginSystem.load_files_from_path(CHARACTER_PATH, NEEDED_FILES, self, "discover_character")
	print("Loading characters finished")
	
	print_loaded_characters()

func print_loaded_characters() -> void:
	print("Loaded characters:")
	for i in characters:
		print("\t" + i)

func get_loaded_characters() -> Array:
	return characters.duplicate()

func load_character(name: String) -> Spatial:
	return load(CHARACTER_PATH + "/" + name + "/" + CHARACTER_FILENAME).instance()

func load_character_splash(name) -> Resource:
	return load(CHARACTER_PATH + "/" + name + "/" + CHARACTER_SPLASHNAME)
