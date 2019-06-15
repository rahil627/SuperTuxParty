extends "../item.gd"

func _init().(TYPES.DICE):
	is_consumed = false

func activate(_player, _controller):
	return (randi() % 6) + 1
