extends Control

const USER_CONFIG_FILE := "user://controls.cfg"

const ACTIONS := ["up", "left", "down", "right", "ok", "pause",
		"action1", "action2", "action3", "action4"]

signal quit

var player_id setget set_player_id

# The eventname that is currently remapped
var control_remap_event
# The button which triggered the remap
var control_remap_button

func set_player_id(id: int):
	player_id = id
	
	for action in ACTIONS:
		var entry := "player{num}_{action}".format({"num": player_id, "action": action})
		var list := InputMap.get_action_list(entry)
		
		var node := $PanelContainer/VBoxContainer/Grid/Column1.get_node_or_null(action)
		if not node:
			node = $PanelContainer/VBoxContainer/Grid/Column2.get_node_or_null(action)
		ControlHelper.set_button_to_event(node.get_node("Button"), list[0])
	
	$Back.grab_focus()

func _ready():
	for action in ACTIONS:
		var node := $PanelContainer/VBoxContainer/Grid/Column1.get_node_or_null(action)
		if not node:
			node = $PanelContainer/VBoxContainer/Grid/Column2.get_node_or_null(action)
		var button := node.get_node("Button")
		button.connect("pressed", self, "_control_remap_pressed", [action, button])

# Taken and adapted from the Godot demos
func load_controls():
	var config = ConfigFile.new()
	var err = config.load(USER_CONFIG_FILE)
	if err: # ConfigFile probably not present, create it
		save_controls()
	else: # ConfigFile was properly loaded, initialize InputMap
		for action_name in InputMap.get_actions():
			if action_name.substr(0, 3) == "ui_" or not config.has_section_key("input", action_name):
				continue
			
			# Get the key scancode corresponding to the saved human-readable string
			var entry = config.get_value("input", action_name)
			
			entry = entry.split(" ", false)
			var event
			# Each entry is as follows [0: "device (int)", 1: "type (string)", ...]
			match entry[1]:
				"Keyboard":
					event = InputEventKey.new()
					event.scancode = int(entry[2])
					event.pressed = true
				"Mouse":
					event = InputEventMouseButton.new()
					event.button_index = int(entry[2])
					event.pressed = true
				"JoypadAxis":
					event = InputEventJoypadMotion.new()
					event.axis = int(entry[2])
					event.axis_value = int(entry[3])
				"JoypadButton":
					event = InputEventJoypadButton.new()
					event.button_index = int(entry[2])
					event.pressed = true
			
			event.device = int(entry[0])
			
			# Replace old action (key) events by the new one
			for old_event in InputMap.get_action_list(action_name):
				if old_event is InputEventKey:
					InputMap.action_erase_event(action_name, old_event)
			InputMap.action_add_event(action_name, event)

# Taken and adapted from the godot demos
func save_controls():
	var config = ConfigFile.new()

	for action_name in InputMap.get_actions():
		if action_name.substr(0, 3) == "ui_":
			continue
		
		var event = InputMap.get_action_list(action_name)[0]
		
		# Each entry is as follows [0: "device (int)", 1: "type (string)", ...]
		var value = var2str(event.device)
		if event is InputEventKey:
			value += " Keyboard " + var2str(event.scancode)
		elif event is InputEventMouseButton:
			value += " Mouse " + var2str(event.button_index)
		elif event is InputEventJoypadMotion:
			value += " JoypadAxis " + var2str(event.axis) + " " + var2str(event.axis_value)
		elif event is InputEventJoypadButton:
			value += " JoypadButton " + var2str(event.button_index)
		
		config.set_value("input", action_name, value)
	config.save(USER_CONFIG_FILE)

func _control_remap_pressed(event: String, button: Button):
	control_remap_event = "player{num}_{action}".format({"num": player_id, "action": event})
	control_remap_button = button
	button.set_text("MENU_LABEL_PRESS_ANY_KEY")

# The min value of the axis to get chosen during remap
# prevents choosing the axis with a little value over one with a large value
const JOYPAD_DEADZONE_REMAP = 0.5

func _input(event: InputEvent):
	var valid_type := event is InputEventKey or event is InputEventMouseButton or event is InputEventJoypadMotion or event is InputEventJoypadButton
	var mousebutton_pressed_check := ((not event is InputEventMouseButton) or (event as InputEventMouseButton).pressed)
	var joypad_deadzone_check := ((not event is InputEventJoypadMotion) or abs(event.axis_value) >= JOYPAD_DEADZONE_REMAP)
	
	if valid_type and control_remap_event and mousebutton_pressed_check and joypad_deadzone_check:
		get_tree().set_input_as_handled()
		ControlHelper.set_button_to_event(control_remap_button, event)
		
		# Remove old keybindings
		for old_event in InputMap.get_action_list(control_remap_event):
			InputMap.action_erase_event(control_remap_event, old_event)
		# Add the new key binding
		InputMap.action_add_event(control_remap_event, event)
		
		save_controls()
		
		control_remap_event = null
		control_remap_button = null

func _on_Back_pressed():
	hide()
	emit_signal("quit")
