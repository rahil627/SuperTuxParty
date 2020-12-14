extends Node

func position_beneath(node: Spatial, control: Control):
	var offset = Vector2(control.rect_size.x / 2, -5)
	control.rect_position = node.get_viewport().get_camera().unproject_position(node.translation) - offset

func position_above(node: Spatial, control: Control):
	var offset = Vector2(control.rect_size.x / 2, -(control.rect_size.y + 5))
	control.rect_position = node.get_viewport().get_camera().unproject_position(node.translation + Vector3(0, 2, 0)) - offset

func load_character(player_id: int, parent: Spatial, animation: String = ""):
	var player = Global.players[player_id - 1]
	var model = PluginSystem.character_loader.load_character(player.character)
	model.name = "Model"
	parent.add_child(model)
	model.freeze_animation()
	if animation:
		get_tree().create_timer(3).connect("timeout", self, "_start_animation", [model, animation])

func _start_animation(model: Spatial, animation: String):
	model.resume_animation()
	model.play_animation(animation)

var needed_oks = 0

func _ready():
	get_viewport().connect("size_changed", self, "_update_viewport_size")
	$ViewportContainer/Viewport.size = get_viewport().size
	yield(get_tree(), "idle_frame")
	get_tree().create_timer(4).connect("timeout", $UIUpdate, "start")
	for node in get_tree().get_nodes_in_group("continue_check"):
		node.connect("accepted", self, "_on_continue")
		needed_oks += 1

func _update_viewport_size():
	$ViewportContainer/Viewport.size = get_viewport().size
	
	for i in range(1, 5):
		var node = get_node_or_null("ViewportContainer/Viewport/Placement{0}".format([i]))
		if not node:
			continue
		position_beneath(node, node.get_node("VBoxContainer"))
		var winner_text = node.get_node_or_null("WinnerText")
		if winner_text:
			position_above(node, winner_text)

func _on_continue():
	needed_oks -= 1
	if needed_oks == 0:
		# Let the sound finish
		get_tree().create_timer(0.5).connect("timeout", Global, "_goto_scene_board")
