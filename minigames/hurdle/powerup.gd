extends Area

export(float) var speed = 6

export(float) var rotation_speed = 3

func _physics_process(delta):
	translation.z -= speed * delta
	if translation.z < -4:
		queue_free()
	
	rotation.y += delta * rotation_speed
