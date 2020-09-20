extends Spatial

const MAX_KNOCKOUT := 3
var knocked_out := 0

var minigame_time := 20.0

var winner := -1

func win(team: int):
	winner = team
	$Screen/Label.show()
	$EndTimer.start()

func _process(delta: float):
	if winner != -1:
		return
	
	minigame_time -= delta
	if minigame_time <= 0:
		minigame_time = 0
		win(0)
		
	$Screen/Time.text= var2str(stepify(minigame_time, 0.1))

func knockout():
	if winner != -1:
		return
	
	knocked_out += 1
	if knocked_out == MAX_KNOCKOUT:
		win(1)

func _on_EndTimer_timeout():
	Global.minigame_team_win(winner)

func _on_Countdown_finish():
	$Screen/Time.show()

func _on_SpawnTimer_timeout():
	if winner != -1:
		return
	
	var pos := Vector3(rand_range(-2.5, 2.5), 5, rand_range(-2.5, -0.5))
	
	var box = preload("res://plugins/minigames/bowling/box.tscn").instance()
	box.translation = pos
	add_child(box)
