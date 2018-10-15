extends Spatial

var id = -1
var next_node = null
onready var controller = get_tree().get_nodes_in_group("Controller")[0]

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
	if (event.is_action("ui_accept") or event.is_action("left_mouse_pressed")) and controller.selected_id == id:
		pressed()

func pressed():
	var player = controller.players[controller.player_turn - 1]
	
	controller.next_node = self.next_node;
	controller.end_turn = true
	controller.do_step(player, controller.steps_remaining)
	
	controller.selected_id = -1
	
	for a in get_tree().get_nodes_in_group("arrows"):
		a.queue_free()
