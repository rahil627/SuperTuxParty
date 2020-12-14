extends "../common.gd"

func setup_scene():
	var node = $ViewportContainer/Viewport/Placement
	var player_id = Global.minigame_summary.minigame_teams[0][0]
	var cakes = Global.minigame_summary.reward
	if Global.minigame_summary.placement:
		load_character(player_id, node, "happy")
	else:
		load_character(player_id, node, "sad")
		$ViewportContainer/Viewport/Placement/WinnerText.hide()
	
	var ui_container: Control = node.get_node("VBoxContainer")
	ui_container.get_node("ContinueCheck").player_id = player_id
	var cookie_text = ui_container.get_node("CookieText")
	cookie_text.total_cookies = Global.players[player_id - 1].cakes
	cookie_text.cookies = -cakes
	position_beneath(node, ui_container)
	position_above(node, $ViewportContainer/Viewport/Placement/WinnerText)

func _ready():
	setup_scene()
	if not Global.minigame_summary.placement:
		$Background/AudioStreamPlayer.stream = preload("res://assets/sounds/minigame_end_screen/stuxparty_lossjingle.ogg")
