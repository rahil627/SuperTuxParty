extends "../item.gd"

func _init():
	type = DICE
	
	is_consumed = false

func activate(player, controller):
	return (randi() % 6) + 1
