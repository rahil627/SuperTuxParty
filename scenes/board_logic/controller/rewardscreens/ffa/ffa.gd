extends "../common.gd"

func setup_scene():
	var i := 0
	var pos := 1
	for p in Global.minigame_summary.placement:
		for player_id in p:
			i += 1
			var node: Position3D = get_node("ViewportContainer/Viewport/Placement" + str(i))
			load_character(player_id, node, "happy" if pos < 4 else "sad")
			
			var ui_container: Control = node.get_node("VBoxContainer")
			position_beneath(node, ui_container)
			
			ui_container.get_node("ContinueCheck").player_id = player_id
			
			var cookie_text = ui_container.get_node("CookieText")
			cookie_text.total_cookies = Global.players[player_id - 1].cookies
			cookie_text.cookies = Global.minigame_summary.reward[i - 1]
		pos += len(p)

func _ready():
	setup_scene()
