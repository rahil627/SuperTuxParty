extends Container

const USER_OPTIONS_FILE = "user://options.cfg"

var _options_file = ConfigFile.new()
var _is_loading_options = false

var control_remapper = preload("res://scenes/menus/control_remapper.gd").new(self)

signal quit

func _ready():
	var joypad_display_types = $TabContainer/Controls/JoypadDisplayType
	joypad_display_types.add_item("Numbers", Global.JOYPAD_DISPLAY_TYPE.NUMBERS)
	joypad_display_types.add_item("XBOX", Global.JOYPAD_DISPLAY_TYPE.XBOX)
	joypad_display_types.add_item("Nintendo DS", Global.JOYPAD_DISPLAY_TYPE.NINTENDO_DS)
	joypad_display_types.add_item("Playstation", Global.JOYPAD_DISPLAY_TYPE.PLAYSTATION)
	load_options()
	
	control_remapper.controls_remapping_setup()

func _input(event):
	control_remapper._input(event)

func _on_Fullscreen_toggled(button_pressed):
	OS.window_fullscreen = button_pressed
	
	save_option("visual", "fullscreen", button_pressed)

func _on_VSync_toggled(button_pressed):
	OS.vsync_enabled = button_pressed
	
	save_option("visual", "vsync", button_pressed)

func _on_FrameCap_item_selected(ID):
	match ID:
		0:
			Engine.target_fps = 30
		1:
			Engine.target_fps = 60
		2:
			Engine.target_fps = 120
		3:
			Engine.target_fps = 144
		4:
			Engine.target_fps = 240
		5:
			Engine.target_fps = 0 # A zero value uncaps the frames.
	
	save_option("visual", "frame_cap", ID)

func _on_bus_toggled(enabled, index):
	AudioServer.set_bus_mute(index, not enabled)
	
	save_option("audio", AudioServer.get_bus_name(index).to_lower() + "_muted", not enabled)

func _on_volume_changed(value, index):
	AudioServer.set_bus_volume_db(index, value)
	
	var percentage = str((value + 80) / 80 * 100).pad_decimals(0) + "%"
	match index:
		0:
			$TabContainer/Audio/Master/Label.text = percentage
		1:
			$TabContainer/Audio/Music/Label.text = percentage
		2:
			$TabContainer/Audio/Effects/Label.text = percentage
	
	save_option("audio", AudioServer.get_bus_name(index).to_lower() + "_volume", value)

func _on_MuteUnfocus_toggled(button_pressed):
	Global.mute_window_unfocus = button_pressed
	
	save_option("audio", "mute_window_unfocus", button_pressed)

func _on_JoypadDisplayType_item_selected(ID):
	Global.joypad_display = ID
	
	control_remapper.controls_remapping_setup()
	
	save_option("controls", "joypad_display_type", ID)

func _on_PauseUnfocus_toggled(button_pressed):
	Global.pause_window_unfocus = button_pressed
	
	save_option("misc", "pause_window_unfocus", button_pressed)

func get_option_value_safely(section, key, default, min_value=null, max_value=null):
	var value = _options_file.get_value(section, key, default)
	if typeof(value) != typeof(default) or min_value != null and value < min_value or max_value != null and value > max_value:
		return default
	
	return value

func load_options():
	var err = _options_file.load(USER_OPTIONS_FILE)
	if err != OK:
		print("Error while loading options: " + Utility.error_code_to_string(err))
		return
	
	_is_loading_options = true # Avoid saving options while loading them.
	
	OS.window_fullscreen = get_option_value_safely("visual", "fullscreen", false)
	$TabContainer/Visual/Fullscreen.pressed = OS.window_fullscreen
	
	OS.vsync_enabled = get_option_value_safely("visual", "vsync", false)
	$TabContainer/Visual/VSync.pressed = OS.vsync_enabled
	
	var frame_id = get_option_value_safely("visual", "frame_cap", 1, 0, 3)
	_on_FrameCap_item_selected(frame_id)
	$TabContainer/Visual/FrameCap/OptionButton.select(frame_id)
	
	AudioServer.set_bus_mute(0, get_option_value_safely("audio", "master_muted", false))
	AudioServer.set_bus_mute(1, get_option_value_safely("audio", "music_muted", false))
	AudioServer.set_bus_mute(2, get_option_value_safely("audio", "effects_muted", false))
	
	$TabContainer/Audio/Master/CheckBox.pressed = not AudioServer.is_bus_mute(0)
	$TabContainer/Audio/Music/CheckBox.pressed = not AudioServer.is_bus_mute(1)
	$TabContainer/Audio/Effects/CheckBox.pressed = not AudioServer.is_bus_mute(2)
	
	Global.mute_window_unfocus = get_option_value_safely("audio", "mute_window_unfocus", true)
	$TabContainer/Audio/MuteUnfocus.pressed = Global.mute_window_unfocus
	
	# Setting the 'value' of 'Range' nodes directly also fires their signals.
	$TabContainer/Audio/MasterVolume.value = get_option_value_safely("audio", "master_volume", 0.0, -80, 0)
	$TabContainer/Audio/MusicVolume.value = get_option_value_safely("audio", "music_volume", 0.0, -80, 0)
	$TabContainer/Audio/EffectsVolume.value = get_option_value_safely("audio", "effects_volume", 0.0, -80, 0)
	
	Global.joypad_display = get_option_value_safely("controls", "joypad_display_type", Global.JOYPAD_DISPLAY_TYPE.NUMBERS, 0, Global.JOYPAD_DISPLAY_TYPE.size() - 1)
	$TabContainer/Controls/JoypadDisplayType.select(Global.joypad_display)
	
	Global.pause_window_unfocus = get_option_value_safely("misc", "pause_window_unfocus", true)
	$TabContainer/Misc/PauseUnfocus.pressed = Global.pause_window_unfocus
	
	_is_loading_options = false

func save_option(section, key, value):
	if _is_loading_options:
		return
	
	_options_file.set_value(section, key, value)
	var err = _options_file.save(USER_OPTIONS_FILE)
	if err != OK:
		print("Error while saving options: " + Utility.error_code_to_string(err))
