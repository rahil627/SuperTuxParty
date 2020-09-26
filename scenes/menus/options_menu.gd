extends VBoxContainer

const USER_OPTIONS_FILE = "user://options.cfg"

var _options_file = ConfigFile.new()
var _is_loading_options = false

#warning-ignore:unused_signal
signal quit

func _ready():
	# Populate with toggled translations in 'Project Settings > Localization > Locales Filter'.
	var languages = ProjectSettings.get("locale/locale_filter")[1]
	var language_control = $TabContainer/Visual/Language/OptionButton
	for i in languages.size():
		language_control.add_item(
				TranslationServer.get_locale_name(languages[i]), i + 1)
		language_control.set_item_metadata(i + 1, languages[i])
	
	load_options()

func _input(event):
	if get_focus_owner() != $Back:
		if event.is_action_pressed("ui_focus_prev"):
			$TabContainer.current_tab = ($TabContainer.current_tab + $TabContainer.get_tab_count() - 1) % $TabContainer.get_tab_count()
			$TabContainer.get_current_tab_control().get_child(0).grab_focus()
			get_tree().set_input_as_handled()
		elif event.is_action_pressed("ui_focus_next"):
			$TabContainer.current_tab = ($TabContainer.current_tab + 1) % $TabContainer.get_tab_count()
			$TabContainer.get_current_tab_control().get_child(0).grab_focus()
			get_tree().set_input_as_handled()

func _on_Fullscreen_toggled(button_pressed):
	OS.window_fullscreen = button_pressed
	
	save_option("visual", "fullscreen", button_pressed)

func _on_VSync_toggled(button_pressed):
	OS.vsync_enabled = button_pressed
	
	save_option("visual", "vsync", button_pressed)

func _on_Language_item_selected(ID):
	var locales = ProjectSettings.get("locale/locale_filter")[1]
	var option_meta = $TabContainer/Visual/Language/OptionButton.get_item_metadata(ID)
	if option_meta == "":
		TranslationServer.set_locale(OS.get_locale())
	elif not locales.has(option_meta):
		TranslationServer.set_locale(OS.get_locale())
		
		save_option("visual", "language", "")
		Global.emit_signal("language_changed")
		return
	
	TranslationServer.set_locale(option_meta)
	
	save_option("visual", "language", option_meta)
	Global.emit_signal("language_changed")

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
	
	var language = get_option_value_safely("visual", "language", "")
	var language_id = ProjectSettings.get("locale/locale_filter")[1].find(language)
	if language_id == -1:
		language_id = 0
	else:
		language_id += 1
	_on_Language_item_selected(language_id)
	$TabContainer/Visual/Language/OptionButton.select(language_id)
	
	OS.window_fullscreen = get_option_value_safely("visual", "fullscreen", false)
	$TabContainer/Visual/Fullscreen.pressed = OS.window_fullscreen
	
	OS.vsync_enabled = get_option_value_safely("visual", "vsync", false)
	$TabContainer/Visual/VSync.pressed = OS.vsync_enabled
	
	var frame_id = get_option_value_safely("visual", "frame_cap", 1, 0, 5)
	_on_FrameCap_item_selected(frame_id)
	$TabContainer/Visual/FrameCap/OptionButton.select(frame_id)
	
	var quality = get_option_value_safely("visual", "quality", 0)
	$TabContainer/Visual/Quality/OptionButton.select(quality)
	
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

func _on_GraphicQuality_item_selected(ID):
	match ID:
		0: # High
			ProjectSettings.set_setting("rendering/quality/shadow_atlas/size", 8192)
			ProjectSettings.set_setting("rendering/quality/directional_shadow/size", 8192)
			ProjectSettings.set_setting("rendering/quality/shadows/filter_mode", 1)
			ProjectSettings.set_setting("rendering/quality/shading/force_vertex_shading", false)
		1: # Medium
			ProjectSettings.set_setting("rendering/quality/shadow_atlas/size", 4096)
			ProjectSettings.set_setting("rendering/quality/directional_shadow/size", 4096)
			ProjectSettings.set_setting("rendering/quality/shadows/filter_mode", 1)
			ProjectSettings.set_setting("rendering/quality/shading/force_vertex_shading", false)
		2: # Low
			ProjectSettings.set_setting("rendering/quality/shadow_atlas/size", 2048)
			ProjectSettings.set_setting("rendering/quality/directional_shadow/size", 2048)
			ProjectSettings.set_setting("rendering/quality/shadows/filter_mode", 0)
			ProjectSettings.set_setting("rendering/quality/shading/force_vertex_shading", false)
	$AcceptDialog.dialog_text = "MENU_GRAPHIC_QUALITY_REBOOT_NOTICE"
	
	$AcceptDialog.popup_centered()
	save_option("visual", "quality", ID)
	
	# Kind of ugly way to get it working
	# The graphic options must be loaded before the engine starts up, because
	# some options can not be changed after initialization
	#
	# So the only possibility to change them is to change the value loaded in the project settings
	# But we don't want to override the local render settings on a new version (it's stored in the pck distributed with the game after all)
	# 
	# Luckily, Godot offers a way to load a custom project settings file, which we naturally point to 'user://render_settings.godot'
	# There we are able to change all settings we like and they will persist
	# But we should not just save the options with `ProjectSettings.save_custom`
	# because this will save everything, but we just want the render settings, as the remaining settings could be updated in a new game version
	#
	# Therefore we're forging such a file. This is an horrible hack and I hope Godot 4.0 will have a better way to do this
	#
	# Idea found here: https://github.com/godotengine/godot/issues/30087#issuecomment-505879289
	var file = ConfigFile.new()
	file.set_value("rendering", "quality/shadow_atlas/size", ProjectSettings.get_setting("rendering/quality/shadow_atlas/size"))
	file.set_value("rendering", "quality/directional_shadow/size", ProjectSettings.get_setting("rendering/quality/directional_shadow/size"))
	file.set_value("rendering", "quality/shadows/filter_mode", ProjectSettings.get_setting("rendering/quality/shadows/filter_mode"))
	file.set_value("rendering", "quality/shading/force_vertex_shading", ProjectSettings.get_setting("rendering/quality/shading/force_vertex_shading"))

	file.save("user://render_settings.godot")

func _on_change_controls_pressed(player_id: int):
	hide()
	$CanvasLayer/ControlRemapper.player_id = player_id
	$CanvasLayer/ControlRemapper.show()

func _on_ControlRemapper_quit():
	show()
	var button := $TabContainer/Controls.get_child($CanvasLayer/ControlRemapper.player_id - 1)
	button.grab_focus()
