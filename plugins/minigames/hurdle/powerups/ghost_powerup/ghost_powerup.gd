extends "../powerup.gd"


func _on_GhostPowerup_body_entered(body):
	if body.is_in_group("players"):
		body.disable_collision(2)
		queue_free()
