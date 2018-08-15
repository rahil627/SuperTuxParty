extends Object

# The directory from which plugins are loaded. Plugins have to be either in .zip or .pck file format
const PLUGIN_DIRECTORY = "plugins"

const NATIVE = true; # Only use files present in the project, no external files. Useful for testing

# loads all .pck and .zip files into the res:// file system
func read_content_packs():
	var dir = Directory.new()
	var err = dir.open(PLUGIN_DIRECTORY)
	if(err != OK):
		# TODO convert error code to error string
		print("Unable to open directory '" + filename + "'. Debug error code: " + String(err))
		return
	dir.list_dir_begin(true) # Parameter indicates to skip . and ..
	
	while true:
		var file = dir.get_next()
		
		if file == "":
			break
		elif not dir.current_is_dir() and (file.ends_with(".pck") or file.ends_with(".zip")):
			if(ProjectSettings.load_resource_pack(PLUGIN_DIRECTORY + "/" + file)):
				print("Successfully loaded plugin: " + file)
			else:
				print("Error while loading plugin: " + file)
		elif not dir.current_is_dir():
			print("Failed to load plugin: " + file + " is neither a .pck nor a .zip file")
	dir.list_dir_end()

func _init():
	if not NATIVE:
		print("Loading plugins...")
		read_content_packs()
		print("Loading plugins finished")
