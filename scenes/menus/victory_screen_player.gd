extends Spatial

var destination

func _process(delta):
	if destination:
		var dir = (destination - translation).normalized()
		rotation.y = atan2(dir.x, dir.z)
		translation += dir * delta * 4
		
		if (destination - translation).length() < 2*delta:
			destination = null
			rotation = Vector3(0, 0, 0)
			$Model.play_animation("happy")
