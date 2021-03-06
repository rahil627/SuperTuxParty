extends Spatial

func handle_event(player: Spatial, space: Spatial):
	match space.name:
		"Node6":
			player.walk_to($Nodes/Node27)
		"Node25":
			player.walk_to($Nodes/Node26)
		"Node31":
			player.walk_to($Nodes/Node29)
		"Node26":
			player.walk_to($Nodes/Node25)
		"Node27":
			player.walk_to($Nodes/Node6)
		"Node29":
			player.walk_to($Nodes/Node31)
		"Node15":
			player.walk_to($Nodes/Node50)
		"Node19":
			player.walk_to($Nodes/Node41)
		"Node41":
			player.walk_to($Nodes/Node19)
		"Node50":
			player.walk_to($Nodes/Node15)

	yield(player, "walking_ended")
	$Controller.continue()
