extends Spatial

const MAX_CONSECUTIVE_HURDLES := 1

var players_alive := 4
var players_finished := 0
var placement := []

var speedup_timeout := 10.0

var direction := 0.05
var time_to_direction_change := 1.0

var stop := false

func _ready():
	placement.resize(players_alive)

func _process(delta: float):
	if stop:
		return
	if abs(direction) < 1.0:
		direction += sign(direction) * delta * 0.2
		direction = clamp(direction, -1.0, 1.0)
	elif speedup_timeout == 0.0:
		direction += sign(direction) * delta * 0.05
		direction = clamp(direction, -8, 8)
	else:
		speedup_timeout -= delta
		if speedup_timeout <= 0.0:
			#$Environment/Screen/Message.text = "Overtime"
			speedup_timeout = 0.0
	time_to_direction_change -= delta
	if time_to_direction_change <= 0.0:
		direction = - direction
		time_to_direction_change += randf() * 5.0 + 1.0
	$conveyor_belt/AnimationPlayer.playback_speed = direction
	var players = get_tree().get_nodes_in_group("players")
	for player in players:
		if not player.dead and player.translation.y < -10:
			player.dead = true
			player.hide()
			placement[players_alive - 1] = player.player_id
			players_alive -= 1
			if players_alive <= 1:
				stop = true
				get_tree().create_timer(1).connect("timeout", self, "finished")

func finished():
	for player in get_tree().get_nodes_in_group("players"):
		if not player.dead:
			placement[players_alive - 1] = player.player_id
			players_alive -= 1
	Global.minigame_win_by_position(placement)
