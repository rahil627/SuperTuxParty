extends "powerup.gd"

func _ready():
	# Make the AI jump over it
	add_to_group("hurdles")

func _on_Landmine_body_entered(body):
	if body.is_in_group("players"):
		body.disable_jump = 0.25
		body.movement = Vector3(0, 7, -2)
		queue_free()
