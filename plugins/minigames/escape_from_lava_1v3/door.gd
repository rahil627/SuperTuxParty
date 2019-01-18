extends StaticBody

var can_be_opened = true

func destroy():
	$"Scene Root/AnimationPlayer".play("destroy")
	$CollisionShape.disabled = true

func open():
	if can_be_opened:
		$"Scene Root/AnimationPlayer".play("open")
		$CollisionShape.disabled = true
		can_be_opened = false

func _on_Area_body_entered(body):
	if body.is_in_group("players"):
		open()
