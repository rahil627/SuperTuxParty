extends Spatial

const SPEED = 2

func _ready():
	$Armature/AnimationPlayer.play("fly-start")
	$Armature/AnimationPlayer.queue("fly")

func _process(delta):
	var dir = Vector3(-self.translation.x, 0, -self.translation.z).normalized()
	self.rotation.y = atan2(dir.x, dir.z)
	self.translation += dir * delta * SPEED

func _on_Area_body_entered(body):
	if body.is_in_group("player"):
		queue_free()

func _on_Area_area_entered(area):
	if area.is_in_group("target"):
		get_parent().end_game()
