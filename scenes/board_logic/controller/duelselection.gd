extends Control

onready var controller: Node = get_tree().get_nodes_in_group("Controller")[0]

func select(state, player, players: Array):
	players = players.duplicate()
	players.remove(players.find(player))

	var i := 1
	for p in players:
		var node = get_node("Player" + str(i))
		var character = Global.players[p.player_id - 1].character
		var texture = PluginSystem.character_loader.load_character_icon(character)
		node.texture_normal = texture

		node.connect("focus_entered", self, "_on_focus_entered", [node])
		node.connect("focus_exited", self, "_on_focus_exited", [node])
		node.connect("mouse_entered", self, "_on_mouse_entered", [node])
		node.connect("mouse_exited", self, "_on_mouse_exited", [node])
		node.connect("pressed", self, "_on_duel_opponent_select",
							[state, player.player_id, p.player_id])
		i += 1

	$Player1.grab_focus()
	show()

func _on_duel_opponent_select(state, self_id: int, other_id: int) -> void:
	state.minigame_teams = [[other_id], [self_id]]

	hide()
	yield(controller.show_minigame_animation(state), "completed")
	controller.show_minigame_info(state)

func _on_focus_entered(button) -> void:
	button.material.set_shader_param("enable_shader", true)

func _on_focus_exited(button) -> void:
	button.material.set_shader_param("enable_shader", false)

func _on_mouse_entered(button) -> void:
	button.material.set_shader_param("enable_shader", true)

func _on_mouse_exited(button) -> void:
	if not button.has_focus():
		button.material.set_shader_param("enable_shader", false)
