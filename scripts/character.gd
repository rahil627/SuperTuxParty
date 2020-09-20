extends Spatial

export(NodePath) var animations
export(NodePath) var collision_shape

func play_animation(name: String):
	if animations:
		var player = get_node(animations)
		if player is AnimationPlayer:
			player.play(name)
		elif player is AnimationTree:
			var state_machine = player["parameters/playback"]
			state_machine.travel(name)

func freeze_animation():
	if animations:
		var player = get_node(animations)
		if player is AnimationPlayer:
			player.playback_speed = 0
		elif player is AnimationTree:
			player.active = false

func resume_animation():
	if animations:
		var player = get_node(animations)
		if player is AnimationPlayer:
			player.playback_speed = 1
		elif player is AnimationTree:
			var state_machine = player["parameters/playback"]
			var current_animation = state_machine.get_current_node()
			player.active = true
			state_machine.start(current_animation)
