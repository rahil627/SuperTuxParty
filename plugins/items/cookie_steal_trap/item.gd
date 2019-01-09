extends "../item.gd"

func _init().(PLACABLE):
	is_consumed = true
	
	can_be_bought = true
	item_cost = 2

func activate(from_player, trap_player, controller):
	var cookies = min(from_player.cookies, 10)
	
	from_player.cookies -= cookies
	trap_player.cookies += cookies
	
	# Removes the trap from the node
	return true
