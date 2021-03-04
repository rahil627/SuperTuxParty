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

func jump_to_animation(name: String):
	if animations:
		var player = get_node(animations)
		if player is AnimationPlayer:
			player.play(name)
		elif player is AnimationTree:
			var state_machine = player["parameters/playback"]
			# We can't just start the animation with start(name), because the default state
			# will replace our animation when the scene was just loaded
			# So we have to force it into the default state
			player.advance(0)
			# Godot doesn't check if such a animation exists
			# Which will cause an infinite error loop
			# That's why we need to check it
			# TODO: may remove this check once fixed in Godot
			if player.tree_root.has_node(name):
				state_machine.start(name)

func freeze_animation():
	if animations:
		var player = get_node(animations)
		if player is AnimationPlayer:
			player.playback_speed = 0
		elif player is AnimationTree:
			# Force an animation update or else it will get stuck in the default pose
			# when instantly frozen
			player.advance(0)
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
