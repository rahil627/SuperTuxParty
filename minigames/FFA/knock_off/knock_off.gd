extends Spatial

var losses = 0 # Number of players that have been knocked-out
var placement = [0, 0, 0, 0] # Placements, is filled with player id in order. Index 0 is first place
var timer_end = 4 # How long the winning message will be shown before exiting
var timer_end_start = false # When to start the end timer

func _ready():
	var i = 1
	$Environment/Screen/Message.hide()
	
	for p in get_tree().get_nodes_in_group("players"):
		p.player_id = i
		i += 1

func _process(delta):
	var players = get_tree().get_nodes_in_group("players")
	for p in players:
		if p.translation.y < -10:
			losses += 1
			placement[4 - losses] = p.player_id # Assign placement before deleting player
			p.queue_free()
	
	if players.size() <= 1 and not timer_end_start:
		# If the last player has not died yet, put him as the winner
		if players.size() == 1:
			placement[0] = players[0].player_id
			players[0].winner = true
		timer_end_start = true
		
		for p in Global.players:
			if p.player_id == placement[0]:
				$Environment/Screen/Message.text = p.player_name + " wins!"
		
		$Environment/Screen/Message.show()
	
	if timer_end_start:
		timer_end -= delta
		if timer_end <= 0:
			Global.goto_board(placement)