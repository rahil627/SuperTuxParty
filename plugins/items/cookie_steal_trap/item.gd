extends Item

func _init().(TYPES.PLACABLE) -> void:
	is_consumed = true

	can_be_bought = true
	item_cost = 2

func activate_trap(from_player: Spatial, trap_player: Spatial,
		_controller: Spatial):
	var cookies = int(min(from_player.cookies, 10))

	from_player.cookies -= cookies
	trap_player.cookies += cookies

	# Removes the trap from the node.
	return true
