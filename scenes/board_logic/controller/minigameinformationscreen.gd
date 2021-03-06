extends Control

var state

func _ready():
	hide()
	self.modulate = Color.transparent

func get_team(id: int) -> int:
	for i in range(len(state.minigame_teams)):
		if id in state.minigame_teams[i]:
			return i
	return -1

func _load_content(minigame, players):
	var TEAM_COLOR = [Color(0xEE3E39FF), Color(0x3030AAFF)]
	var TEAM_MINIGAMES = [Global.MINIGAME_TYPES.ONE_VS_THREE,
			Global.MINIGAME_TYPES.TWO_VS_TWO]

	$Content/Rows/Description/Text.bbcode_text = tr(minigame.description)

	var container: GridContainer = $Content/Rows/Controls
	container.columns = 2 * len(players) + 1
	for child in container.get_children():
		child.queue_free()
	# A spacer where the control description is
	container.add_child(Control.new())
	# Add the player names
	for player in players:
		container.add_child(VSeparator.new())
		var header := PanelContainer.new()
		header.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		var box = HBoxContainer.new()
		var label = Label.new()
		match state.minigame_type:
			Global.MINIGAME_TYPES.ONE_VS_THREE, Global.MINIGAME_TYPES.TWO_VS_TWO:
				var style = StyleBoxFlat.new()
				style.bg_color = TEAM_COLOR[get_team(player.player_id)]
				style.expand_margin_left = 2
				style.expand_margin_right = 2
				style.expand_margin_top = 2
				style.expand_margin_bottom = 8
				style.corner_radius_top_left = 5
				style.corner_radius_top_right = 5
				if minigame.controls.empty():
					style.expand_margin_bottom = 2
					style.corner_radius_bottom_left = 5
					style.corner_radius_bottom_right = 5
				header.add_stylebox_override("panel", style)
			_:
				header.add_stylebox_override("panel", StyleBoxEmpty.new())
		label.text = player.player_name
		var texture = TextureRect.new()
		var character = Global.players[player.player_id - 1].character
		texture.texture = PluginSystem.character_loader.load_character_icon(character)
		texture.size_flags_vertical = SIZE_EXPAND_FILL
		texture.size_flags_horizontal = SIZE_EXPAND_FILL
		texture.expand = true
		texture.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT
		box.add_child(label)
		box.add_child(texture)
		header.add_child(box)
		container.add_child(header)
	for entry in minigame.controls:
		for i in range(2 * len(players) + 1):
			if i % 2 == 0:
				container.add_child(HSeparator.new())
			else:
				container.add_child(Control.new())
		var label := preload("res://scenes/board_logic/controller/templates/control_text.tscn").instance()
		label.bbcode_text = tr(entry.text)
		container.add_child(label)
		for player in players:
			container.add_child(VSeparator.new())
			var panel = PanelContainer.new()
			match state.minigame_type:
				Global.MINIGAME_TYPES.ONE_VS_THREE, Global.MINIGAME_TYPES.TWO_VS_TWO:
					var style = StyleBoxFlat.new()
					style.bg_color = TEAM_COLOR[get_team(player.player_id)]
					style.expand_margin_left = 2
					style.expand_margin_right = 2
					style.expand_margin_top = 5
					style.expand_margin_bottom = 8
					if entry == minigame.controls[-1]:
						style.corner_radius_bottom_left = 5
						style.corner_radius_bottom_right = 5
						style.expand_margin_bottom = 2
					panel.add_stylebox_override("panel", style)
				_:
					panel.add_stylebox_override("panel", StyleBoxEmpty.new())
			var controls := VBoxContainer.new()
			var first_row := HBoxContainer.new()
			var second_row := HBoxContainer.new()
			controls.size_flags_vertical = SIZE_SHRINK_CENTER
			first_row.alignment = BoxContainer.ALIGN_CENTER
			second_row.alignment = BoxContainer.ALIGN_CENTER
			controls.add_child(first_row)
			controls.add_child(second_row)
			if not "team" in entry:
				panel.add_child(controls)
			elif state.minigame_type in TEAM_MINIGAMES:
				if get_team(player.player_id) == entry.team:
					panel.add_child(controls)
			container.add_child(panel)
			var first_row_count: int
			if len(entry.actions) > 2:
				# Put half of the entries in the first row, rounded up
				first_row_count = (len(entry.actions) + 1) / 2
			else:
				first_row_count = len(entry.actions)
			for index in range(len(entry.actions)):
				var action = entry.actions[index]
				var element
				if action == "spacer":
					element = preload("res://scenes/board_logic/controller/templates/control_spacer.tscn").instance()
				else:
					var action_name = "player{num}_{action}".format({"num": player.player_id, "action": action})
					var input = InputMap.get_action_list(action_name)[0]
					element = ControlHelper.ui_from_event(input)
				if index < first_row_count:
					first_row.add_child(element)
				else:
					second_row.add_child(element)

func show_minigame_info(state, players: Array) -> void:
	Global.load_minigame_translations(state.minigame_config)
	self.state = state

	$Buttons/Play.grab_focus()

	$Title.text = state.minigame_config.name
	match state.minigame_type:
		Global.MINIGAME_TYPES.DUEL:
			$Mode.text = "MINIGAME_TYPE_DUEL"
		Global.MINIGAME_TYPES.FREE_FOR_ALL:
			$Mode.text = "MINIGAME_TYPE_FFA"
		Global.MINIGAME_TYPES.GNU_COOP:
			$Mode.text = "MINIGAME_TYPE_GNU_COOP"
		Global.MINIGAME_TYPES.GNU_SOLO:
			$Mode.text = "MINIGAME_TYPE_GNU_SOLO"
		Global.MINIGAME_TYPES.NOLOK_COOP:
			$Mode.text = "MINIGAME_TYPE_NOLOK_COOP"
		Global.MINIGAME_TYPES.NOLOK_SOLO:
			$Mode.text = "MINIGAME_TYPE_NOLOK_SOLO"
		Global.MINIGAME_TYPES.ONE_VS_THREE:
			$Mode.text = "MINIGAME_TYPE_1v3"
		Global.MINIGAME_TYPES.TWO_VS_TWO:
			$Mode.text = "MINIGAME_TYPE_2v2"
	var filtered_players = []
	for team in state.minigame_teams:
		for player_id in team:
			for player in players:
				if player.player_id == player_id:
					filtered_players.append(player)
	Global.connect("language_changed", self, "_load_content",
			[state.minigame_config, filtered_players])
	_load_content(state.minigame_config, filtered_players)
	if state.minigame_config.image_path != null:
		$Content/Rows/Description/Screenshot.texture = \
				load(state.minigame_config.image_path)

	$AnimationPlayer.play("fade_in")
	show()

func _on_Try_pressed() -> void:
	state.is_try = true
	Global.goto_minigame(state)

func _on_Play_pressed() -> void:
	state.is_try = false
	Global.goto_minigame(state)
