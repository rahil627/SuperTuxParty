tool
extends EditorPlugin

var open_dialog
var edit_dialog

func _enter_tree():
	yield(get_tree(), "idle_frame")
	add_tool_menu_item("Missing Minigame Configs", self, "create_minigame_config")
	add_tool_menu_item("Open Minigame Config", self, "open_minigame_config")
	open_dialog = load("res://addons/minigame_config_dialog/open.tscn").instance()
	edit_dialog = load("res://addons/minigame_config_dialog/edit.tscn").instance()
	get_editor_interface().get_base_control().add_child(open_dialog)
	get_editor_interface().get_base_control().add_child(edit_dialog)

func _exit_tree():
	remove_tool_menu_item("Missing Minigame Configs")
	remove_tool_menu_item("Open Minigame Config")
	open_dialog.free()
	edit_dialog.free()

func create_minigame_config(_arg):
	var without_config := []
	var dir := Directory.new()
	dir.open("res://plugins/minigames")
	dir.list_dir_begin(true)
	var name = dir.get_next()
	while name:
		var file = File.new()
		if not file.file_exists("res://plugins/minigames/" + name + "/minigame.json"):
			without_config.push_back(name)
		name = dir.get_next()
	dir.list_dir_end()
	
	open_dialog.set_options(without_config)
	open_dialog.popup_centered()
	var file = yield(open_dialog, "selected")
	if file:
		open_file(file, false)

func open_minigame_config(_arg):
	var with_config := []
	var dir := Directory.new()
	dir.open("res://plugins/minigames")
	dir.list_dir_begin(true)
	var name = dir.get_next()
	while name:
		var file = File.new()
		if file.file_exists("res://plugins/minigames/" + name + "/minigame.json"):
			with_config.push_back(name)
		name = dir.get_next()
	dir.list_dir_end()
	
	open_dialog.set_options(with_config)
	open_dialog.popup_centered()
	var file = yield(open_dialog, "selected")
	if file:
		open_file(file, true)

func open_file(file, load_from_disk: bool):
	edit_dialog.path = "res://plugins/minigames/" + file + "/minigame.json"
	if load_from_disk:
		edit_dialog.load_from_file()
	edit_dialog.popup_centered()
