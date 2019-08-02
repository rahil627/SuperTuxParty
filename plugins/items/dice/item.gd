extends Item

func _init().(TYPES.DICE) -> void:
	is_consumed = false

func activate(_player: Spatial, _controller: Spatial):
	return (randi() % 6) + 1
