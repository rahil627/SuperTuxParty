const USER_CONFIG_FILE = "user://controls.cfg"

const CONTROL_HELPER = preload("res://controlhelper.gd")

# The eventname that is currently remapped
var control_remap_event
# The button which triggered the remap
var control_remap_button

var main_menu

func _init(main_menu):
	self.main_menu = main_menu

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

# loads for every player an instance of player_controls_template.tscn and assigns a click handler to every button
func controls_remapping_setup():
	load_controls()
	var controls_tab = main_menu.get_node("OptionsMenu/Buttons/TabContainer/Controls/TabContainer")
	for player_id in range(4):
		var template = preload("player_controls_template.tscn")
		var instance = template.instance()
		instance.set_name("Player" + var2str(player_id+1))
		controls_tab.add_child(instance)
		
		# Iterating over all direct children of our template
		# Every child's name should be the event, e.g. up for event player1_up
		# and it must have a Button named child
		for child in instance.get_children():
			if child.has_node("Button"):
				var button = child.get_node("Button")
				var event_name = "player" + var2str(player_id + 1) + "_" + child.get_name()
				var input_event = InputMap.get_action_list(event_name)[0]
				if input_event != null:
					button.text = CONTROL_HELPER.get_button_name(input_event)
					button.connect("pressed", self, "_control_remap_pressed", [event_name, button])

func _control_remap_pressed(event, button):
	control_remap_event = event
	control_remap_button = button
	button.set_text("Press a key")

# The min value of the axis to get chosen during remap
# prevents choosing the axis with a little value over one with a large vlaue
const JOYPAD_DEADZONE_REMAP = 0.5

func _input(event):
	var valid_type = event is InputEventKey or event is InputEventMouseButton or event is InputEventJoypadMotion or event is InputEventJoypadButton
	var mousebutton_pressed_check = ((not event is InputEventMouseButton) or event.pressed)
	var joypad_deadzone_check = ((not event is InputEventJoypadMotion) or abs(event.axis_value) >= JOYPAD_DEADZONE_REMAP)
	
	if valid_type and control_remap_event != null and mousebutton_pressed_check and joypad_deadzone_check:
		main_menu.get_tree().set_input_as_handled()
		control_remap_button.text = CONTROL_HELPER.get_button_name(event)
		
		# Remove old keybindings
		for old_event in InputMap.get_action_list(control_remap_event):
			InputMap.action_erase_event(control_remap_event, old_event)
		# Add the new key binding
		InputMap.action_add_event(control_remap_event, event)
		
		save_controls()
		
		control_remap_event = null
		control_remap_button = null
