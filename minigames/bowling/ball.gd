extends KinematicBody

const SPEED = 10
const MAX_TIME = 4

var time = 0

func _process(delta):
	time += delta
	
	if time > MAX_TIME:
		queue_free()
		return
	
	var forward = Vector3(sin(rotation.y), 0, cos(rotation.y))
	
	var collider = move_and_collide(forward * SPEED * delta)
	
	if collider != null and collider.collider != null:
		if collider.collider.is_in_group("players"):
			queue_free()
			collider.collider.knockout(Vector3(0, 3.5, -8))
