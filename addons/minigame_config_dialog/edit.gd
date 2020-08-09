tool
extends PopupPanel

const MINIGAME_TYPES := ["1v3", "2v2", "Duel", "FFA", "GnuCoop", "GnuSolo", "NolokCoop", "NolokSolo"]
const CONTROL_ACTIONS := ["up", "left", "down", "right", "action1", "action2", "action3", "action4"]

var path: String
var file_dialog: EditorFileDialog

func _enter_tree():
	file_dialog = EditorFileDialog.new()
	file_dialog.current_path = path
	file_dialog.access = EditorFileDialog.ACCESS_RESOURCES
	add_child(file_dialog)

func _ready():
	$VBoxContainer/HBoxContainer2/MainScene.connect("pressed", self, "_set_file", [$VBoxContainer/HBoxContainer2/MainScene, FileDialog.MODE_OPEN_FILE])
	$VBoxContainer/HBoxContainer3/Screenshot.connect("pressed", self, "_set_file", [$VBoxContainer/HBoxContainer3/Screenshot, FileDialog.MODE_OPEN_FILE])
	$VBoxContainer/HBoxContainer4/Translations.connect("pressed", self, "_set_file", [$VBoxContainer/HBoxContainer4/Translations, FileDialog.MODE_OPEN_DIR])

func load_from_file():
	var minigame_loader = load("res://scripts/minigame_loader.gd")
	var config = minigame_loader.parse_file(path)
	if not config:
		return
	$VBoxContainer/HBoxContainer/Name.text = config.name
	$VBoxContainer/HBoxContainer2/MainScene.text = config.scene_path
	if config.image_path:
		$VBoxContainer/HBoxContainer3/Screenshot.text = config.image_path
	else:
		$VBoxContainer/HBoxContainer3/Screenshot.text = "..."
	if config.translation_directory:
		$VBoxContainer/HBoxContainer4/Translations.text = config.translation_directory
	else:
		$VBoxContainer/HBoxContainer4/Translations.text = "..."
	$VBoxContainer/HBoxContainer6/Description.text = config.description
	
	$VBoxContainer/HBoxContainer5/Type.unselect_all()
	for type in config.type:
		var idx = MINIGAME_TYPES.find(type)
		if idx >= 0:
			$VBoxContainer/HBoxContainer5/Type.select(idx, false)
	
	for child in $VBoxContainer/HBoxContainer7/List/ScrollContainer/VBoxContainer.get_children():
		child.free()
	for control in config.controls:
		var template = load("res://addons/minigame_config_dialog/control_entry.tscn").instance()
		for action in control.actions:
			var idx = CONTROL_ACTIONS.find(action);
			if idx < 0:
				continue
			template.get_node("Actions").select(idx, false)
		template.get_node("Text").text = control.text
		$VBoxContainer/HBoxContainer7/List/ScrollContainer/VBoxContainer.add_child(template)

func _set_file(button, mode):
	file_dialog.mode = mode
	file_dialog.popup_centered_minsize(Vector2(600, 500))
	if mode == FileDialog.MODE_OPEN_FILE:
		button.text = yield(file_dialog, "file_selected")
	else:
		button.text = yield(file_dialog, "dir_selected")

func _on_Save_pressed():
	var types := []
	for i in $VBoxContainer/HBoxContainer5/Type.get_selected_items():
		types.append(MINIGAME_TYPES[i])
	if $VBoxContainer/HBoxContainer2/MainScene.text == "...":
		$AcceptDialog.dialog_text = "No main scene selected. Config was not saved."
		$AcceptDialog.popup_centered()
		return
	if not types:
		$AcceptDialog.dialog_text = "No minigame types selected. Config was not saved."
		$AcceptDialog.popup_centered()
		return
	var file := File.new()
	file.open(path, File.WRITE)
	
	var dict := {}
	dict["name"] = $VBoxContainer/HBoxContainer/Name.text
	dict["scene_path"] = $VBoxContainer/HBoxContainer2/MainScene.text
	if $VBoxContainer/HBoxContainer3/Screenshot.text != "...":
		dict["image_path"] = $VBoxContainer/HBoxContainer3/Screenshot.text
	if $VBoxContainer/HBoxContainer4/Translations.text != "...":
		dict["translation_directory"] = $VBoxContainer/HBoxContainer4/Translations.text
	dict["type"] = types
	dict["description"] = $VBoxContainer/HBoxContainer6/Description.text
	var controls := []
	for child in $VBoxContainer/HBoxContainer7/List/ScrollContainer/VBoxContainer.get_children():
		var actions := []
		for i in child.get_node("Actions").get_selected_items():
			actions.append(CONTROL_ACTIONS[i])
		controls.append({"actions": actions, "text": child.get_node("Text").text})
	dict["controls"] = controls
	file.store_string(JSON.print(dict, "\t"))
	file.close()
	hide()

func _on_Add_pressed():
	var template = load("res://addons/minigame_config_dialog/control_entry.tscn").instance()
	$VBoxContainer/HBoxContainer7/List/ScrollContainer/VBoxContainer.add_child(template)

func _on_PopupPanel_about_to_show():
	$VBoxContainer/HBoxContainer/Name.grab_click_focus()

func _on_Close_pressed():
	hide()
