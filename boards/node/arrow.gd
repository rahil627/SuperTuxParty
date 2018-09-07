extends Spatial

var id = -1
var next_node = null
var controller = null

func _ready():
	controller = get_tree().get_nodes_in_group("Controller")[0]
	add_to_group("arrows")

func _process(delta):
	if controller == null:
		print("[arrow.gd] Warning: controller could not be found")
		return
	
	if controller.selected_id == id:
		$Sprite.modulate = Color(1.0, 1.0, 1.0, 1.0)
	else:
		$Sprite.modulate = Color(1.0, 0.5, 0.5, 0.3)

func _on_Arrow_mouse_entered():
	controller.selected_id = id

func _on_Arrow_mouse_exited():
	if controller.selected_id == id:
		controller.selected_id = -1

func _on_Arrow_input_event(camera, event, click_position, click_normal, shape_idx):
	if (event.is_action("ui_accept") || event.is_action("left_mouse_pressed")) && controller.selected_id == id:
		pressed()

func pressed():
	var player = controller.players[controller.player_turn - 2]
	var previous_space = player.space
	
	player.space = next_node
	
	var players_on_space = controller.get_players_on_space(player.space) - 1
	var offset = controller.EMPTY_SPACE_PLAYER_TRANSLATION
	
	if players_on_space > 0:
		offset = controller.PLAYER_TRANSLATION[players_on_space]
	
	player.destination.append(player.space.translation + offset)
	
	controller.end_turn = true
	
	if controller.steps_remaining > 1:
		controller.do_step(player, controller.steps_remaining)
	else:
		controller.update_space(previous_space)
		controller.update_space(player.space)
	
	controller.selected_id = -1
	
	for a in get_tree().get_nodes_in_group("arrows"):
		a.queue_free()
