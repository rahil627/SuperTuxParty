extends Control

export(int, 1, 8) var max_health = 1

func _ready():
	if Engine.editor_hint:
		for i in range(4):
			get_node("Player%dName" % i).text = "Player%d" % i
			for j in range(max_health):
				var heart_container = load("res://scenes/overlays/player_health.tscn").instance()
				get_node("Player%dHealth" % i).add_child(heart_container)
	else:
		var i = 1
		
		for team in Global.minigame_teams:
			for player_id in team:
				get_node("Player%dName" % i).text = Global.players[player_id - 1].player_name
				for j in range(max_health):
					var heart_container = load("res://scenes/overlays/player_health.tscn").instance()
					# If it's on the right side, make it being used up from the middle
					if i % 2 == 0:
						heart_container.fill_mode = TextureProgress.FILL_RIGHT_TO_LEFT
					
					get_node("Player%dHealth" % i).add_child(heart_container)
				
				i += 1
		
		while i < Global.amount_of_players:
			get_node("Player%dName" % i).queue_free()
			get_node("Player%dHealth" % i).queue_free()
			
			i += 1

func set_health(player_id, health):
	if health < 0:
		health = 0
	
	var children = get_node("Player%dHealth" % player_id).get_children()
	
	# Make the hearts be used in reverse order if its on the right side
	# This makes the heart being used up from the center
	# Sadly there is no possibility to reverse the HBoxContainer layout order
	if player_id %2 == 0:
		children.invert()
	
	for child in children:
		child.value = clamp(health, 0, 1)
		health -= 1

func get_health(player_id):
	var health = 0
	for child in get_node("Player%dHealth" % player_id).get_children():
		health += child.value
	
	return health
