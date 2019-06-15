extends Spatial

signal arrow_activated

var next_node = null

var next_arrow = null
var previous_arrow = null

var selected = false setget set_selected

func set_selected(enable):
	selected = enable
	
	if selected:
		$Sprite.modulate = Color(1.0, 1.0, 1.0, 1.0)
		add_to_group("selected_arrow")
	else:
		$Sprite.modulate = Color(1.0, 0.5, 0.5, 0.3)
		remove_from_group("selected_arrow")

func _on_Arrow_mouse_entered():
	# Unselect the current selected arrow
	for arrow in get_tree().get_nodes_in_group("selected_arrow"):
		arrow.selected = false
	
	self.selected = true

func _on_Arrow_input_event(_camera, event, _click_position, _click_normal, _shape_idx):
	if event.is_action_pressed("left_mouse_pressed"):
		pressed()

func _unhandled_input(event):
	if selected:
		if event.is_action_pressed("ui_accept"):
			pressed()
			# Prevents duplicate activation 
			get_tree().set_input_as_handled()
		elif event.is_action_pressed("ui_left"):
			self.selected = false
			previous_arrow.selected = true
			# Prevents the next arrow from acting on this input too
			get_tree().set_input_as_handled()
		elif event.is_action_pressed("ui_right"):
			self.selected = false
			next_arrow.selected = true
			# Prevents the next arrow from acting on this input too
			get_tree().set_input_as_handled()

func pressed():
	for a in get_tree().get_nodes_in_group("arrows"):
		a.queue_free()
	
	emit_signal("arrow_activated")
