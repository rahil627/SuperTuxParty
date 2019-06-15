extends Control

export(Texture) var icon setget set_icon
export(int) var startscore = 0

func _ready():
	if Engine.editor_hint:
		for i in range(4):
			get_node("Player%dName" % i).text = "Player%d" % i
			get_node("Player%dScoreIcon" % i).texture = icon
			get_node("Player%dScore" % i).text = str(startscore)
	else:
		var i = 1
		
		for team in Global.minigame_teams:
			for player_id in team:
				get_node("Player%dName" % i).text = Global.players[player_id - 1].player_name
				
				get_node("Player%dScoreIcon" % i).texture = icon
				get_node("Player%dScore" % i).text = str(startscore)
				
				i += 1
		
		while i < Global.amount_of_players:
			get_node("Player%dName" % i).queue_free()
			get_node("Player%dScoreIcon" % i).queue_free()
			get_node("Player%dScore" % i).queue_free()
			
			i += 1

func set_score(player_id, score):
	get_node("Player%dScore" % player_id).text = str(score)

func get_score(player_id):
	return int(get_node("Player%dScore" % player_id).text)

func set_icon(tex):
	icon = tex
	
	if is_inside_tree():
		for i in range(4):
			get_node("Player%dScoreIcon" % i).texture = icon