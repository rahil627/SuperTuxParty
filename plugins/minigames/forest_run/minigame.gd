extends Spatial

func fire_catapults():
	for i in range(1, 8):
		get_node("Catapult" + str(i)).fire()
		yield(get_tree().create_timer(0.1), "timeout")

func _process(_delta: float):
	$Remaining.text = str(stepify($Timer2.time_left, 0.1))

func _on_Finish_body_entered(_body):
	Global.minigame_gnu_win()

func _on_Timer2_timeout():
	Global.minigame_gnu_loose()
