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

			new_model.play_animation("idle")
			if i > 0:
				new_model.freeze_animation()

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

func _load_content(minigame, players):
	$Description/Text.bbcode_text = tr(minigame.description)

	for i in range(1, len(players) + 1):
		var container: VBoxContainer = $Controls.get_node_or_null("Player" + str(i) + "/Rows")
		if not minigame_has_player(i) or players[i - 1].is_ai:
			# If the player is controlled by an AI, there is no point in
			# showing controls.
			if container:
				container.get_parent().queue_free()
			continue
		for child in container.get_children():
			child.queue_free()

		for entry in minigame.controls:
			var row := HBoxContainer.new()
			row.alignment = BoxContainer.ALIGN_CENTER
			
			var controls := VBoxContainer.new()
			var first_row := HBoxContainer.new()
			var second_row := HBoxContainer.new()
			controls.size_flags_vertical = SIZE_SHRINK_CENTER
			controls.add_child(first_row)
			controls.add_child(second_row)
			row.add_child(controls)
			container.add_child(row)
			var first_row_count: int
			if len(entry.actions) > 2:
				# Put half of the entries in the first row, rounded up
				first_row_count = (len(entry.actions) + 1) / 2
			else:
				first_row_count = len(entry.actions)
			for index in range(len(entry.actions)):
				var action = entry.actions[index]
				var action_name = "player{num}_{action}".format({"num": i, "action": action})
				var input = InputMap.get_action_list(action_name)[0]
				if index < first_row_count:
					first_row.add_child(ControlHelper.ui_from_event(input))
				else:
					second_row.add_child(ControlHelper.ui_from_event(input))
			var seperator := Label.new()
			seperator.text = "-"
			row.add_child(seperator)
			var label := preload("res://scenes/board_logic/controller/templates/control_text.tscn").instance()
			label.bbcode_text = tr(entry.text)
			row.add_child(label)

func show_minigame_info(state, players: Array) -> void:
	Global.load_minigame_translations(state.minigame_config)
	self.state = state
	setup_character_viewport()

	$Buttons/Play.grab_focus()

	$Title.text = state.minigame_config.name
	Global.connect("language_changed", self, "_load_content", [state.minigame_config, players])
	_load_content(state.minigame_config, players)
	if state.minigame_config.image_path != null:
		$Description/Screenshot.texture =\
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

	# Pause the animation, when it is no longer selected
	last_player.freeze_animation()

	player.resume_animation()

	$Characters/Viewport/Indicator.translation = player.translation + Vector3(0, 1.5, 0)
