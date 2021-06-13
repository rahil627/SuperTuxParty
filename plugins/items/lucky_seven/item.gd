extends Item

func _init().(TYPES.DICE, "Lucky Seven") -> void:
	is_consumed = true
	
	can_be_bought = true
	item_cost = 2

func get_description() -> String:
	return "Use this special dice to roll a guaranteed seven!"

func activate(_player: Spatial, _controller: Spatial):
	return 7
