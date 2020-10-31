extends RigidBody

var max_speed = 2
var accel = 10

var team
var player_id = 0
var is_ai = false
var ai_difficulty: int

var winner = false setget set_winner

var is_walking = false

func set_winner(win):
	winner = win
	
	if not is_walking and win:
		$Model.play_animation("happy")

func _ready():
	$Model.set_as_toplevel(true)
	
	if is_ai:
		match ai_difficulty:
			Global.Difficulty.EASY:
				accel = 7
				max_speed *= 0.8
			Global.Difficulty.NORMAL:
				accel = 10
				max_speed *= 0.9
			Global.Difficulty.HARD:
				accel = 11

func get_distance_to_shape(point):
	var edges = get_parent().ground_edges
	var distance = INF
	
	for e in edges:
		var p1 = e[0]
		var p2 = e[1]
		
		var dir = (p2 - p1).normalized()
		var r = dir.dot(point - p1)
		
		r = clamp(r, 0, 1)
		
		var dist = sqrt(pow((point - p1).length(), 2) - r * pow((p2-p1).length(), 2))
		if dist < distance:
			distance = dist
	
	return distance

func is_on_floor():
	return translation.y > 2.4

func _process(delta):
	var dir = Vector3()
	
	$Model.translation = self.translation + Vector3(0, 0.5, 0)
	
	var players = get_tree().get_nodes_in_group("players")
	
	if not is_ai and is_on_floor():
		dir.x = Input.get_action_strength("player%d_down" % player_id) - Input.get_action_strength("player%d_up" % player_id)
		dir.z = Input.get_action_strength("player%d_left" % player_id) - Input.get_action_strength("player%d_right" % player_id)
	elif is_on_floor():
		# Try to knock off the player, that is the farthest away from the center, yet still on the ice
		var farthest_player = null
		var farthest_distance = INF
		for p in players:
			if p != self and (p.team != self.team or Global.minigame_state.minigame_type == Global.MINIGAME_TYPES.FREE_FOR_ALL):
				var distance = get_distance_to_shape(p.translation)
				if p.is_on_floor() and (farthest_player == null or farthest_distance > distance):
					farthest_player = p
					farthest_distance = distance
		
		if farthest_player != null:
			dir = (farthest_player.translation - translation).rotated(Vector3(0, 1, 0), PI/2)
		else:
			# Everybody knocked off the board?
			# Move towards the center
			dir = self.translation.rotated(Vector3(0, 1, 0), -PI/2)
			
			if dir.length_squared() < 0.1:
				dir = Vector3()
	
	dir = dir.normalized()
	
	if dir.length_squared() > 0:
		add_torque(dir * accel)
		var target_rotation = atan2(-dir.z, dir.x)
		
		var diff1 = (target_rotation - $Model.rotation.y)
		var diff2 = (target_rotation + sign($Model.rotation.y) * TAU - $Model.rotation.y)
		
		if abs(diff1) < abs(diff2):
			$Model.rotation.y += diff1 * delta * 3
		else:
			$Model.rotation.y += diff2 * delta * 3
		
		if not is_walking:
			$Model.play_animation("walk")
			is_walking = true
	else:
		if is_walking:
			if winner:
				$Model.play_animation("happy")
			else:
				$Model.play_animation("idle")
			is_walking = false
	
	if angular_velocity.length() > max_speed:
		angular_velocity = max_speed * angular_velocity.normalized()
