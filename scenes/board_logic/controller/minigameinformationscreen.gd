extends Control

var state

func setup_character_viewport() -> void:
	var i := 1
	for team in state.minigame_teams:
		for player_id in team:
			var player =\
					$Characters/Viewport.get_node("Player" + var2str(i))
			var character = Global.players[player_id - 1].character
			var new_model = PluginSystem.character_loader.load_character(character)

			new_model.name = player.name
			new_model.translation = player.translation
			new_model.scale = player.scale
			new_model.rotation = player.rotation

			player.replace_by(new_model)

			if new_model.has_node("AnimationPlayer"):
				new_model.get_node("AnimationPlayer").play("idle")
				if i > 0:
					new_model.get_node("AnimationPlayer").playback_speed = 0

			i += 1

	while i <= Global.amount_of_players:
		var player = $Characters/Viewport.get_node(
				"Player" + var2str(i))
		player.hide()

		i += 1

func minigame_has_player(id: int) -> bool:
	for team in state.minigame_teams:
		for player_id in team:
			if player_id == id:
				return true

	return false

func _get_translation(source) -> String:
	if source is String:
		return tr(source)
	var locale: String = TranslationServer.get_locale()

	if source.has(locale):
		return source.get(locale)
	elif source.has(locale.substr(0, 2)):
		# Check if, e.g. de is present if locale is de_DE.
		return source.get(locale.substr(0, 2))
	elif source.has("en"):
		return source.en
	else:
		var values = source.values()
		if values.size() > 0:
			return values[0]

		return "Unable to get translation"

func _load_content(minigame, players):
	$Description/Text.bbcode_text = _get_translation(minigame.description)

	for i in range(1, len(players) + 1):
		var label: RichTextLabel = $Controls.get_node("Player" + str(i))
		if not minigame_has_player(i) or players[i - 1].is_ai:
			# If the player is controlled by an AI, there is no point in
			# showing controls.
			if label:
				label.queue_free()
			continue

		label.bbcode_text = ""
		for action in minigame.controls:
			var action_name = "player{num}_{action}".format({"num": i, "action": action})
			var input = InputMap.get_action_list(action_name)[0]
			var control = ControlHelper.get_from_event(input)
			if control is String:
				if input is InputEventKey:
					# There isn't a special image for all keys.
					# For ones such as 'a' we generally impose the character
					# over a blank texture. This doesn't work in RichTextLabels
					# So we forge such a texture with a viewport
					var img = load("res://scenes/board_logic/controller/inputevent_key_viewport.tscn").instance()
					img.get_node("TextureRect/Label").text = control
					label.add_child(img)
					control = img.get_texture()
				else:
					label.add_text(control)
			if control is Texture:
				var image_height := 32
				var font_height = label.get_font("normal_font").get_ascent()
				var font := BitmapFont.new()
				# Wrapping an image in a font allows to offset it vertically
				# Documentation here: https://docs.godotengine.org/de/latest/tutorials/gui/bbcode_in_richtextlabel.html#image-vertical-offset
				font.ascent = (image_height - font_height) / 2
				label.push_font(font)
				label.add_image(control, 0, image_height)
				label.pop()
			label.append_bbcode(" - " + _get_translation(minigame.controls[action]) + "\n")

func show_minigame_info(state, players: Array) -> void:
	Global.load_minigame_translations(state.minigame_config)
	self.state = state
	setup_character_viewport()

	$Buttons/Play.grab_focus()

	$Title.text = state.minigame_config.name
	Global.connect("language_changed", self, "_load_content", [state.minigame_config, players])
	_load_content(state.minigame_config, players)
	if state.minigame_config.image_path != null:
		$Screenshot.texture =\
				load(state.minigame_config.image_path)

	show()

func _on_Try_pressed() -> void:
	state.is_try = true
	Global.goto_minigame(state)

func _on_Play_pressed() -> void:
	state.is_try = false
	Global.goto_minigame(state)

func _on_Controls_tab_changed(tab: int) -> void:
	var last_tab_selected: int = $Controls.get_previous_tab()
	var last_player = $Characters/Viewport.get_node(
			"Player" + str(last_tab_selected + 1))
	var player = $Characters/Viewport.get_node(
			"Player" + str(tab + 1))

	if last_player.has_node("AnimationPlayer"):
		# Pause the animation, when it is no longer selected
		last_player.get_node("AnimationPlayer").seek(0, true)
		last_player.get_node("AnimationPlayer").playback_speed = 0

	if player.has_node("AnimationPlayer"):
		player.get_node("AnimationPlayer").playback_speed = 1

	$Characters/Viewport/Indicator.translation = player.translation + Vector3(0, 1.5, 0)
