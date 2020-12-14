extends "../common.gd"

func setup_scene():
	var node = $ViewportContainer/Viewport/Placement
	var player_id = Global.minigame_summary.minigame_teams[0][0]
	var ui_container: Control = node.get_node("VBoxContainer")
	ui_container.get_node("ContinueCheck").player_id = player_id
	if Global.minigame_summary.placement:
		load_character(player_id, node, "happy")
		ui_container.get_node("Item/Icon").texture = Global.minigame_summary.reward.icon
		ui_container.get_node("Item/Label").show()
		ui_container.get_node("Item/Icon").show()
	else:
		load_character(player_id, node, "sad")
		$ViewportContainer/Viewport/Placement/WinnerText.hide()
	
	position_beneath(node, ui_container)
	position_above(node, $ViewportContainer/Viewport/Placement/WinnerText)

func _ready():
	setup_scene()
	if not Global.minigame_summary.placement:
		$Background/AudioStreamPlayer.stream = preload("res://assets/sounds/minigame_end_screen/stuxparty_lossjingle.ogg")
