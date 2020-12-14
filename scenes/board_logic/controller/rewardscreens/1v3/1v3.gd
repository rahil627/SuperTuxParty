extends "../common.gd"

func setup_scene():
	var i := 1
	var placement: int = Global.minigame_summary.placement
	for team_id in range(len(Global.minigame_summary.minigame_teams)):
		for player_id in Global.minigame_summary.minigame_teams[team_id]:
			var node: Position3D = get_node("ViewportContainer/Viewport/Placement" + str(i))
			load_character(player_id, node, "happy" if placement == team_id else "sad")
			
			var ui_container = node.get_node("VBoxContainer")
			ui_container.get_node("ContinueCheck").player_id = player_id
			var cookie_text = ui_container.get_node("CookieText")
			cookie_text.total_cookies = Global.players[player_id - 1].cookies
			if placement == team_id:
				cookie_text.cookies = 10 if placement == 1 else 5
				var winner_text = node.get_node("WinnerText")
				position_above(node, winner_text)
				winner_text.show()
			position_beneath(node, ui_container)
			i += 1

func _ready():
	setup_scene()
