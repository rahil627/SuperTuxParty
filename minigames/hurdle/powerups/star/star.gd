extends "../powerup.gd"

const ANIMATION_DURATION = 1
const MIN_SCALE = 0.8
const MAX_SCALE = 1.0

var time = randf() * ANIMATION_DURATION

func _physics_process(delta):
	time += delta
	
	var time_factor = abs((fmod(time, 2*ANIMATION_DURATION) - ANIMATION_DURATION) / ANIMATION_DURATION)
	var scale_factor = MIN_SCALE * time_factor + (1 - time_factor) * MAX_SCALE
	scale = Vector3(scale_factor, scale_factor, scale_factor)

func _on_Star_body_entered(body):
	if body.is_in_group("players"):
		body.acceleration = 2
		queue_free()
