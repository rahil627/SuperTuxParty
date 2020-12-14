extends HBoxContainer

# emitted via signal connection, silencing false positive
#warning-ignore:UNUSED_SIGNAL
signal accepted

export var player_id: int = 0 setget set_player_id

var accepted := false
var time := 0.0

func set_player_id(p: int):
	player_id = p
	var action_name = "player{num}_ok".format({"num": player_id})
	var input = InputMap.get_action_list(action_name)[0]
	$VBoxContainer.add_child(ControlHelper.ui_from_event(input))
	show()

func _process(delta):
	time += delta
	
	if player_id and time >= 5 + 0.1 * player_id and Global.players[player_id - 1].is_ai:
		do_accept()

func do_accept():
	if accepted:
		return
	accepted = true
	$VBoxContainer.queue_free()
	$Label.queue_free()
	$AudioStreamPlayer.play()
	# We don't want to continue before the cookie adding animation has finished
	# However we still want the players be able to press ready before that
	# Therefore we wait until there've been 6 seconds elapsed in the reward screen
	var delay := 6.0 - time
	get_tree().create_timer(delay).connect("timeout", self, "emit_signal", ["accepted"])

func _input(event):
	if Global.players[player_id - 1].is_ai:
		return
	
	if event.is_action_pressed("player{0}_ok".format([player_id])):
		do_accept()
