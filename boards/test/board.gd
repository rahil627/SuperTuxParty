extends Spatial

func fire_event(player, space):
	match space.name:
		"Node6":
			player.space = $Nodes/Node27
			$Controller.update_space(player.space)
		"Node25":
			player.space = $Nodes/Node26
			$Controller.update_space(player.space)
		"Node31":
			player.space = $Nodes/Node29
			$Controller.update_space(player.space)
		"Node26":
			player.space = $Nodes/Node25
			$Controller.update_space(player.space)
		"Node27":
			player.space = $Nodes/Node6
			$Controller.update_space(player.space)
		"Node29":
			player.space = $Nodes/Node31
			$Controller.update_space(player.space)
		"Node15":
			player.space = $Nodes/Node50
			$Controller.update_space(player.space)
		"Node19":
			player.space = $Nodes/Node41
			$Controller.update_space(player.space)
		"Node41":
			player.space = $Nodes/Node19
			$Controller.update_space(player.space)
		"Node50":
			player.space = $Nodes/Node15
			$Controller.update_space(player.space)

