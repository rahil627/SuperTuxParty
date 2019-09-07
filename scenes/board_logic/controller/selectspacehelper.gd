extends Spatial

signal space_selected(space)

onready var controller = get_tree().get_nodes_in_group("Controller")[0]

var selected_space
var selected_space_distance: int
var select_space_max_distance: int

func _ready():
	set_as_toplevel(true)

func get_next_spaces(space: NodeBoard):
	var result = []

	for p in space.next:
		if p.is_visible_space():
			result.append(p)
		else:
			result += get_next_spaces(p)

	return result

func get_prev_spaces(space: NodeBoard):
	var result = []

	for p in space.prev:
		if p.is_visible_space():
			result.append(p)
		else:
			result += get_prev_spaces(p)

	return result

func select_space(player, max_distance: int) -> void:
	if player.is_ai:
		# Select random space in front of or behind player
		var distance: int = (randi() % (2*max_distance + 1)) - max_distance
		selected_space = player.space

		if distance > 0:
			while distance > 0:
				var possible_spaces = get_next_spaces(selected_space)
				if possible_spaces.size() == 0:
					break

				selected_space = possible_spaces[randi() %\
						possible_spaces.size()]
				distance -= 1
		else:
			while distance < 0:
				var possible_spaces = get_prev_spaces(selected_space)
				if possible_spaces.size() == 0:
					break

				selected_space = possible_spaces[randi() %\
						possible_spaces.size()]
				distance += 1

		yield(get_tree().create_timer(1), "timeout")
		emit_signal("space_selected", selected_space)
	else:
		selected_space_distance = 0
		select_space_max_distance = max_distance

		selected_space = player.space
		show_select_space_arrows()

func show_select_space_arrows() -> void:
	var keep_arrow = preload(\
			"res://scenes/board_logic/node/arrow/arrow_keep.tscn").instance()

	keep_arrow.next_node = selected_space
	keep_arrow.translation = selected_space.translation

	keep_arrow.connect("arrow_activated", self,
			"_on_select_space_arrow_activated", [keep_arrow, 0])

	add_child(keep_arrow)

	var previous = keep_arrow

	if selected_space_distance < select_space_max_distance:
		for node in get_next_spaces(selected_space):
			var arrow = preload("res://scenes/board_logic/node/arrow/" +\
					"arrow.tscn").instance()
			var dir: Vector3 = node.translation - selected_space.translation

			dir = dir.normalized()

			arrow.previous_arrow = previous
			previous.next_arrow = arrow

			arrow.next_node = node
			arrow.translation = selected_space.translation
			arrow.rotation.y = atan2(dir.normalized().x, dir.normalized().z)

			arrow.connect("arrow_activated", self,
					"_on_select_space_arrow_activated", [arrow, 1])

			add_child(arrow)
			previous = arrow

	if selected_space_distance > -select_space_max_distance:
		for node in get_prev_spaces(selected_space):
			var arrow = preload("res://scenes/board_logic/node/arrow/" +\
					"arrow.tscn").instance()
			var dir: Vector3 = node.translation - selected_space.translation

			dir = dir.normalized()

			arrow.previous_arrow = previous
			previous.next_arrow = arrow

			arrow.next_node = node
			arrow.translation = selected_space.translation
			arrow.rotation.y = atan2(dir.normalized().x, dir.normalized().z)

			arrow.connect("arrow_activated", self,
					"_on_select_space_arrow_activated", [arrow, -1])

			add_child(arrow)
			previous = arrow

	previous.next_arrow = keep_arrow
	keep_arrow.previous_arrow = previous

	keep_arrow.selected = true

	controller.camera_focus = selected_space

func _on_select_space_arrow_activated(arrow, distance: int) -> void:
	if arrow.next_node == selected_space:
		controller.camera_focus = controller.players[controller.player_turn - 1]

		emit_signal("space_selected", selected_space)
		return

	selected_space = arrow.next_node
	selected_space_distance += distance

	show_select_space_arrows()

