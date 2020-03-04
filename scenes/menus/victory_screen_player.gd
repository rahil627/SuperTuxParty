extends Spatial

var destination

func play_animation(animation: String):
	if $Model.has_node("AnimationPlayer"):
		$Model/AnimationPlayer.play(animation)

func _process(delta):
	if destination:
		var dir = (destination - translation).normalized()
		rotation.y = atan2(dir.x, dir.z)
		translation += dir * delta * 4
		
		if (destination - translation).length() < 2*delta:
			destination = null
			rotation = Vector3(0, 0, 0)
			play_animation("happy")
