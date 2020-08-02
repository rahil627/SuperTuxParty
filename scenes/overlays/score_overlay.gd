tool
extends Control

export(Texture) var icon setget set_icon
export(int) var startscore = 0

var playerid_index = [-1, -1, -1, -1]
var points = [startscore, startscore, startscore, startscore]
var teams = [[], [], [], []]

func _load_character(player_id: int, team_index: int):
	playerid_index[player_id - 1] = team_index
	teams[team_index - 1].append(player_id)

	var character = Global.players[player_id - 1].character
	var icon = PluginSystem.character_loader.load_character_icon(character)

	var texture = TextureRect.new()
	texture.rect_min_size = Vector2(64, 64)
	texture.expand = true
	texture.stretch_mode = TextureRect.STRETCH_SCALE
	texture.texture = icon

	var parent = get_node("Player{0}/Icons".format([team_index]))
	parent.add_child(texture)

func _load_score(team_index: int):
	var parent = get_node("Player{0}".format([team_index]))
	parent.get_node("Score/Icon").texture = self.icon
	parent.get_node("Score/Amount").text = str(startscore)

func _ready():
	if Engine.editor_hint:
		for i in range(4):
			_load_score(i + 1)
	else:
		var i = 1
		
		match Global.minigame_state.minigame_type:
			Global.MINIGAME_TYPES.FREE_FOR_ALL:
				for player_id in Global.minigame_state.minigame_teams[0]:
					_load_character(player_id, i)
					_load_score(i)
					i += 1
			_:
				for team in Global.minigame_state.minigame_teams:
					for player_id in team:
						_load_character(player_id, i)
					_load_score(i)
					i += 1
		
		while i <= Global.amount_of_players:
			get_node("Player{0}".format([i])).queue_free()
			i += 1

func set_score(player_id, score):
	points[player_id - 1] = score
	var index = playerid_index[player_id - 1]
	var total = 0
	for player_id in teams[index - 1]:
		total += points[player_id - 1]
	get_node("Player{0}/Score/Amount".format([index])).text = str(total)

func get_score(player_id):
	return points[player_id - 1]

func set_icon(tex):
	icon = tex
	
	if is_inside_tree():
		for i in range(4):
			var node = get_node_or_null("Player{0}/Score/Icon".format([i + 1]))
			if node:
				node.texture = icon
