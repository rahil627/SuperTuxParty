extends Spatial

var variant: int setget set_variant

var faceup := false

func set_variant(value: int):
	variant = value

	$Front.texture = load("res://plugins/minigames/memory/cards/card_{0}.png".format([value]))

func load_icon(node: Sprite3D, index: int):
	var texture = PluginSystem.character_loader.load_character_icon(Global.players[index].character)
	node.texture = texture
	node.pixel_size = min(1.28 / texture.get_width(), 1.28 / texture.get_height())

func _ready():
	load_icon($Player1, 0)
	load_icon($Player2, 1)
	load_icon($Player3, 2)
	load_icon($Player4, 3)

func flip_up(color: Color = Color.white):
	faceup = true
	$Front.modulate = color
	$AnimationPlayer.play("flip_up")

	return $AnimationPlayer

func flip_down():
	faceup = false
	$AnimationPlayer.play("flip_down")

	return $AnimationPlayer

func is_animation_running() -> bool:
	return $AnimationPlayer.is_playing()

func animation_player() -> AnimationPlayer:
	return $AnimationPlayer as AnimationPlayer

func show_player(player_id: int):
	get_node("Player{0}".format([player_id])).show()

func hide_player(player_id: int):
	get_node("Player{0}".format([player_id])).hide()
