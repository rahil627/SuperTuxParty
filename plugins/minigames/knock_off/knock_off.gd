extends Spatial

var losses = 0 # Number of players that have been knocked-out
var placement# Placements, is filled with player id in order. Index 0 is first place
var timer_end = 4 # How long the winning message will be shown before exiting
var timer_end_start = false # When to start the end timer

var winner_team

var human_players := 0

var ground_edges = {}

func _ready():
	$Environment/Screen/Message.hide()
	
	if Global.minigame_state.minigame_type == Global.MINIGAME_TYPES.DUEL:
		placement = [0, 0]
	else:
		placement = [0, 0, 0, 0]
	
	var i = 1
	for team_id in range(Global.minigame_state.minigame_teams.size()):
		for player in Global.minigame_state.minigame_teams[team_id]:
			var player_node = get_node("Player{0}".format([i]))
			player_node.team = team_id
			if not player_node.is_ai:
				human_players += 1
			i += 1
	
	precompute_ground_edges()

func precompute_ground_edges():
	var collision_shape = $Ground/StaticBody/CollisionShape
	var faces = collision_shape.shape.get_faces()
	var transform = collision_shape.global_transform
	var inward_edges = {}
	
	var i = 0
	while i < faces.size():
		# Skip triangles that are on the bottom or on the side
		# We only want to look at the top shape
		if faces[i].y < 0 or faces[i + 1].y < 0 or faces[i + 2].y < 0:
			i += 3
			continue
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
			
			var edge = [transform * p1, transform * p2]
			var inv_edge = [transform * p2, transform * p1]
			# Idea: each face that is not an outer edge is present two times
			# Therefore to get the outer edges, we have to get all edges
			# that are present only once
			if not inward_edges.has(edge) and not inward_edges.has(inv_edge):
				if ground_edges.has(edge):
					inward_edges[edge] = true
					ground_edges.erase(edge)
				elif ground_edges.has(inv_edge):
					inward_edges[inv_edge] = true
					ground_edges.erase(inv_edge)
				else:
					ground_edges[edge] = true
			p1 = p2
# Uncomment to visualize the resulting edges
#	var geometry = ImmediateGeometry.new()
#	geometry.material_override = SpatialMaterial.new()
#	geometry.material_override.flags_unshaded = true
#	geometry.material_override.render_priority = 1
#	geometry.material_override.albedo_color = Color.red
#	add_child(geometry)
#	geometry.begin(Mesh.PRIMITIVE_LINES)
#	for edge in ground_edges:
#		geometry.add_vertex(edge[0])
#		geometry.add_vertex(edge[1])
#	geometry.end()

func win_condition(players):
	if Global.minigame_state.minigame_type == Global.MINIGAME_TYPES.FREE_FOR_ALL:
		return players.size() <= 1
	else:
		var team
		for p in get_tree().get_nodes_in_group("players"):
			if team != null and p.team != team:
				return false
			team = p.team
		
		return true

func _process(delta):
	var players = get_tree().get_nodes_in_group("players")
	if human_players == 0 and len(players) > 0:
		players[0].max_speed = 5.0
	for p in players:
		if p.translation.y < -10:
			losses += 1
			placement[placement.size() - losses] = p.player_id # Assign placement before deleting player
			if losses == placement.size():
				winner_team = p.team
			if not p.is_ai:
				human_players -= 1
			p.queue_free()
	
	if win_condition(players) and not timer_end_start:
		# If the last player has not died yet, put him as the winner
		if players.size() == 1:
			placement[0] = players[0].player_id
			players[0].winner = true
		
		if not players.empty():
			winner_team = players[0].team
		timer_end_start = true
		
		match Global.minigame_state.minigame_type:
			Global.MINIGAME_TYPES.FREE_FOR_ALL, Global.MINIGAME_TYPES.DUEL:
				for p in Global.players:
					if p.player_id == placement[0]:
						$Environment/Screen/Message.text = tr("KNOCK_OFF_PLAYER_WINS_MSG").format({"player": p.player_name})
			Global.MINIGAME_TYPES.TWO_VS_TWO:
				$Environment/Screen/Message.text = tr("KNOCK_OFF_TEAM_WINS_MSG").format({"team": winner_team + 1})
		
		$Environment/Screen/Message.show()
	
	if timer_end_start:
		timer_end -= delta
		if timer_end <= 0:
			match Global.minigame_state.minigame_type:
				Global.MINIGAME_TYPES.DUEL, Global.MINIGAME_TYPES.FREE_FOR_ALL:
					Global.minigame_win_by_position(placement)
				Global.MINIGAME_TYPES.TWO_VS_TWO:
					Global.minigame_team_win(winner_team)
