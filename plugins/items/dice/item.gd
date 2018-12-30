extends "../item.gd"

func _init().(TYPES.DICE):
	is_consumed = false

func activate(player, controller):
	return (randi() % 6) + 1
