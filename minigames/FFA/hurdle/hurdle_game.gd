extends Spatial

var losses = 0 # Number of players that have been knocked-out
var placement = [0, 0, 0, 0] # Placements, is filled with player id in order. Index 0 is first place
var timer = 50.0 # Timer of minigame
var end_timer = 4 # How long the winning message will be shown before exiting
var end_timer_start = false # When to start the end timer
var spawn_timer = 5
var max_spawn = 5

func _ready():
	var i = 1
	$Environment/Screen/Message.hide()
	
	for p in get_tree().get_nodes_in_group("players"):
		p.player_id = i
		i += 1

func _process(delta):
	spawn_timer -= delta
	
	if spawn_timer < 0:
		max_spawn -= 0.25
		
		if max_spawn < 1.0:
			max_spawn = 1.0
		
		spawn_timer = rand_range(1.0, max_spawn)
		
		var hurdle1 = preload("res://minigames/FFA/hurdle/hurdle.tscn").instance()
		var hurdle2 = preload("res://minigames/FFA/hurdle/hurdle.tscn").instance()
		
		hurdle1.translation = Vector3(1, 0, 16)
		hurdle2.translation = Vector3(-1, 0, 16)
		
		add_child(hurdle1)
		add_child(hurdle2)
	
	var players = get_tree().get_nodes_in_group("players")
	for p in players:
		if p.translation.z < (-4 + p.player_id):
			losses += 1
			placement[4 - losses] = p.player_id # Assign placement before deleting player
			p.queue_free()
	
	if players.size() <= 1:
		# If the last player has not died yet, put him as the winner
		if players.size() == 1:
			placement[0] = players[0].player_id
		end_timer_start = true
		
		for p in $"/root/Global".players:
			if p.player_id == placement[0]:
				$Environment/Screen/Message.text = p.player_name + " wins!"
		
		$Environment/Screen/Message.show()
	
	if end_timer_start:
		end_timer -= delta
		if end_timer <= 0:
			$"/root/Global".goto_board(placement)
	else:
		timer -= delta
		
		if timer <= 0.0:
			end_timer_start = true
			timer = 0.0
			
			# Store the winners based on the z-coordinate
			var winner = [null, null, null, null]
			var winner_index = 0
			
			for p in players:
				if winner[0] == null:
					winner[0] = p
				elif (p.translation.z + p.player_id) > (winner[winner_index].translation.z + winner[winner_index].player_id):
					winner[winner_index + 1] = winner[winner_index]
					winner[winner_index] = p
					
					winner_index += 1
			
			winner_index = 0
			
			for w in winner:
				if placement[winner_index] == 0 && w != null:
					placement[winner_index] = winner[winner_index].player_id
					winner_index += 1
		
		$Environment/Screen/Timer.text = "Timer: " + var2str(stepify(timer, 0.01))