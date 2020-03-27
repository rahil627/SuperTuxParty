extends Control

var state

func setup_character_viewport() -> void:
	var i := 1
	for team in state.minigame_teams:
		for player_id in team:
			var player =\
					$Characters/Viewport.get_node(
					"Player" + var2str(i))
			var new_model = load(Global.character_loader.get_character_path(
					Global.players[player_id - 1].character)).instance()

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

func _get_translation(dictionary: Dictionary) -> String:
	var locale: String = TranslationServer.get_locale()

	if dictionary.has(locale):
		return dictionary.get(locale)
	elif dictionary.has(locale.substr(0, 2)):
		# Check if, e.g. de is present if locale is de_DE.
		return dictionary.get(locale.substr(0, 2))
	elif dictionary.has("en"):
		return dictionary.en
	else:
		var values = dictionary.values()
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
		for action in minigame.used_controls:
			label.append_bbcode(ControlHelper.get_button_name(
					InputMap.get_action_list("player" + str(i) + "_" +
					action)[0]) + " - " + _get_translation(
					minigame.used_controls[action]) + "\n")

func show_minigame_info(state, players: Array) -> void:
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
