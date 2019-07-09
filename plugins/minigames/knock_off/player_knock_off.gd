extends RigidBody

const MAX_SPEED = 4

var team
var player_id = 0
var accel = 15
var is_ai = false

var winner = false setget set_winner

var is_walking = false

var ground_edges = {}

func set_winner(win):
	winner = win
	
	if not is_walking and win and has_node("Model/AnimationPlayer"):
		$Model/AnimationPlayer.play("happy")

func _ready():
	$Model.set_as_toplevel(true)
	
	if has_node("Model/AnimationPlayer"):
		$Model/AnimationPlayer.play("idle")
	
	precompute_ground_edges()

func precompute_ground_edges():
	var faces = $"../Ground/StaticBody/CollisionShape".shape.get_faces()
	var inward_edges = {}
	
	var i = 0
	while i < faces.size():
		var p1 = faces[i]
		for x in range(3):
			i += 1
			var p2
			
			# Triangles, e.g. 0 -> 1 -> 2 form a triangle
			# This method calculates the distance to the edges, therefore needed edges 0 -> 1, 1 -> 2, 2 -> 0
			if x == 2:
				p2 = faces[i - 3]
			else:
				p2 = faces[i]
			
			var edge = [p1, p2]
			var value_hash = edge.hash()
			if not inward_edges.has(value_hash):
				if ground_edges.has(value_hash):
					inward_edges[value_hash] = edge
					ground_edges.erase(value_hash)
				else:
					ground_edges[value_hash] = edge

func get_distance_to_shape(point, edges):
	var distance = INF
	
	for e in edges.values():
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
			if p != self and (p.team != self.team or Global.minigame_type == Global.MINIGAME_TYPES.FREE_FOR_ALL):
				var distance = get_distance_to_shape(p.translation, ground_edges)
				if p.is_on_floor() and (farthest_player == null or farthest_distance > distance):
					farthest_player = p
					farthest_distance = distance
		
		if farthest_player != null:
			dir = (farthest_player.translation - translation).rotated(Vector3(0, 1, 0), PI/2)
		else:
			# Everybody knocked off the board?
			# Move towards the center
			dir = self.translation.rotated(Vector3(0, 1, 0), -PI/2)
	
	dir = dir.normalized()
	
	if dir.length() > 0:
		angular_velocity += dir * accel * delta
		if not is_walking and has_node("Model/AnimationPlayer"):
			$Model/AnimationPlayer.play("walk")
			is_walking = true
	else:
		if is_walking and has_node("Model/AnimationPlayer"):
			if winner:
				$Model/AnimationPlayer.play("happy")
			else:
				$Model/AnimationPlayer.play("idle")
			is_walking = false
	
	if angular_velocity.length() > MAX_SPEED:
		angular_velocity = MAX_SPEED * angular_velocity.normalized()
