extends Control

export(NodePath) var player1
export(NodePath) var player2
export(NodePath) var player3
export(NodePath) var player4

func _ready():
	var size = get_viewport_rect().size
	var player1_viewport = get_node(player1).get_node("Viewport")
	var player2_viewport = get_node(player2).get_node("Viewport")
	
	$Player1.texture = player1_viewport.get_texture()
	$Player2.texture = player2_viewport.get_texture()
	if Global.minigame_type != Global.MINIGAME_TYPES.DUEL:
		var player3_viewport = get_node(player3).get_node("Viewport")
		var player4_viewport = get_node(player4).get_node("Viewport")
		$Player3.texture = player3_viewport.get_texture()
		$Player4.texture = player4_viewport.get_texture()
		
		player1_viewport.size = Vector2(size.x / 2, size.y / 2)
		player2_viewport.size = Vector2(size.x / 2, size.y / 2)
		player3_viewport.size = Vector2(size.x / 2, size.y / 2)
		player4_viewport.size = Vector2(size.x / 2, size.y / 2)
	else:
		player1_viewport.size = Vector2(size.x / 2, size.y)
		player2_viewport.size = Vector2(size.x / 2, size.y)
