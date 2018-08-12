extends StaticBody

var speed = 8

func _ready():
	constant_linear_velocity = Vector3(0, 0, -speed)

func _physics_process(delta):
	translation.z -= speed * delta
	if translation.z < -3.7:
		translation.y -= 9.8 * delta
	if translation.y < -10:
		queue_free()