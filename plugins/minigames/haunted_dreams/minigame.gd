extends Spatial

func end_game():
	$Control/Message.show()
	get_tree().paused = true;
	yield(get_tree().create_timer(3), "timeout")
	get_tree().paused = false
	Global.minigame_gnu_loose()

func _process(_delta):
	$Control/Timer.text = var2str(stepify($Control/Duration.time_left, 0.1))
	
	if $Control/Duration.time_left == 0:
		$Control/Timer.hide()
		$Control/Message.show()
		get_tree().paused = true
		yield(get_tree().create_timer(3), "timeout")
		get_tree().paused = false
		Global.minigame_gnu_win()

func _on_Timer_timeout():
	if $Control/Duration.time_left > 5:
		var dir = randf() * 2 * PI
		var pos = Vector3(cos(dir) * 10, 1, sin(dir) * 10)
		
		var ghost = preload("res://plugins/minigames/haunted_dreams/ghost.tscn").instance()
		ghost.translation = pos
		add_child(ghost)
