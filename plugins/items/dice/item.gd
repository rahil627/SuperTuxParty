extends "../item.gd"

func _init().(DICE):
	is_consumed = false

func activate(player, controller):
	return (randi() % 6) + 1
