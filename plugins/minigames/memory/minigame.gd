extends Spatial

var started := false
var finished := false

func card_at(row: int, column: int) -> Node:
	return get_node("Row{0}/{1}".format([row, column]))

func _ready():
	$Player1.blocked = true
	$Player2.blocked = true
	$Player3.blocked = true
	$Player4.blocked = true

	var variants := [1, 2, 3, 4]

	var places_left := [
		$"Row1/1",
		$"Row1/2",
		$"Row1/3",
		$"Row2/1",
		$"Row2/2",
		$"Row2/3",
		$"Row3/1",
		$"Row3/2",
		$"Row3/3",
		$"Row4/1",
		$"Row4/2",
		$"Row4/3",
	]
	var places_right := [
		$"Row1/5",
		$"Row1/6",
		$"Row1/7",
		$"Row2/5",
		$"Row2/6",
		$"Row2/7",
		$"Row3/5",
		$"Row3/6",
		$"Row3/7",
		$"Row4/5",
		$"Row4/6",
		$"Row4/7",
	]
	places_left.shuffle()
	places_right.shuffle()

	while places_left and places_right:
		var variant = variants[randi() % len(variants)]
		places_left.pop_back().variant = variant
		places_right.pop_back().variant = variant

	for i in range(6):
		$Row1.get_child(i).flip_up()
		$Row2.get_child(i).flip_up()
		$Row3.get_child(i).flip_up()
		$Row4.get_child(i).flip_up()
		yield(get_tree().create_timer(0.1), "timeout")

	yield(get_tree().create_timer(2), "timeout")
	for i in range(6):
		$Row1.get_child(i).flip_down()
		$Row2.get_child(i).flip_down()
		$Row3.get_child(i).flip_down()
		$Row4.get_child(i).flip_down()
		yield(get_tree().create_timer(0.1), "timeout")

	yield(get_tree().create_timer(0.5), "timeout")
	$Player1.blocked = false
	$Player2.blocked = false
	$Player3.blocked = false
	$Player4.blocked = false
	started = true

func _process(_delta):
	if not started:
		return
	
	var unmatched := 0
	var players = [$Player1, $Player2, $Player3, $Player4]
	for player in players:
		# If the player is holding a card open, then it's not yet matched
		# But it also isn't facedown anymore
		if player.blocked:
			unmatched += 1
	for row in range(1, 5):
		for column in range(1, 8):
			if column == 4:
				continue
			var card = card_at(row, column)
			if not card.faceup or card.is_animation_running():
				unmatched += 1
	if not unmatched and not finished:
		$Timer.start()
		finished = true

func _on_Timer_timeout():
	var team1 = $Player1.points + $Player2.points
	var team2 = $Player3.points + $Player4.points
	Global.minigame_team_win_by_points([team1, team2])

