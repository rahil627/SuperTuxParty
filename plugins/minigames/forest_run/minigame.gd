extends Spatial

func fire_catapults():
	for i in range(1, 8):
		get_node("Catapult" + str(i)).fire()
		yield(get_tree().create_timer(0.1), "timeout")

func _on_Finish_body_entered(_body):
	Global.minigame_gnu_win()
