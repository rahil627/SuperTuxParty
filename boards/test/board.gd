extends Spatial

func fire_event(player, space):
	match space.name:
		"Node6", "Node12", "Node14", "Node19", "Node24":
			player.space = get_node("Node26")
			$"Controller".update_space(player.space)
		"Node26", "Node27", "Node28":
			player.space = get_node("Node25")
			$"Controller".update_space(player.space)
