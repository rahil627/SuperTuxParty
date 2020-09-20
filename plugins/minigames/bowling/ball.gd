extends KinematicBody

const SPEED = 10
const MAX_TIME = 4

var time = 0

func _physics_process(delta):
	time += delta
	
	if time > MAX_TIME:
		queue_free()
		return
	
	var forward = Vector3(0, 0, -1)
	
	var collider = move_and_collide(forward * SPEED * delta)
	
	if collider != null and collider.collider != null:
		var object = collider.collider
		if object.is_in_group("players") or object.is_in_group("box"):
			queue_free()
			object.knockout(Vector3(0, 3.5, -8))
