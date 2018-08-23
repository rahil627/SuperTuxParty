extends StaticBody

var speed = 6

func _ready():
	constant_linear_velocity = Vector3(0, 0, -speed)

func _physics_process(delta):
	translation.z -= speed * delta
	if translation.z < -4:
		queue_free()