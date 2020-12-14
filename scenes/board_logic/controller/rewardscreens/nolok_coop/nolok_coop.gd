extends "../common.gd"

func setup_scene():
	var i := 0
	for p in Global.players:
		i += 1
		var player_id = p.player_id
		var node: Position3D = get_node("ViewportContainer/Viewport/Placement" + str(i))
		if Global.minigame_summary.placement:
			load_character(player_id, node, "happy")
		else:
			load_character(player_id, node, "sad")
		
		var ui_container: Control = node.get_node("VBoxContainer")
		ui_container.get_node("ContinueCheck").player_id = player_id
		var cookie_text = ui_container.get_node("CookieText")
		cookie_text.total_cookies = Global.players[player_id - 1].cakes
		cookie_text.cookies = -Global.minigame_summary.reward[i - 1]
		position_beneath(node, ui_container)

func _ready():
	setup_scene()
	if not Global.minigame_summary.placement:
		$Background/AudioStreamPlayer.stream = preload("res://assets/sounds/minigame_end_screen/stuxparty_lossjingle.ogg")
