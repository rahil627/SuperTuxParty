extends KinematicBody

var velocity = Vector3()
var hit_height = 0

func _ready():
	$Sprite3D.set_as_toplevel(true)

func _process(delta):
	var a = -9.81 / 2
	var b = velocity.y
	var c = global_transform.origin.y - hit_height - 0.1
	var time_to_hit = (-b - sqrt(b*b - 4 * a * c)) / (2 * a)
	
	var hit_pos = global_transform.origin + (velocity + Vector3(0, -9.81, 0) * 0.5 * time_to_hit) * time_to_hit
	
	$Sprite3D.translation = hit_pos
	$Sprite3D.opacity = 1 - clamp(time_to_hit - 0.25, 0, 1)
	
	velocity.y -= 9.81 * delta / 2
	var collision = self.move_and_collide(velocity * delta)
	velocity.y -= 9.81 * delta / 2
	
	if collision:
		if collision.collider.is_in_group("player"):
			Global.minigame_gnu_loose()
		
		$Sprite3D.hide()
		self.set_process(false)
		$AnimationPlayer.play("fade")
		yield($AnimationPlayer, "animation_finished")
		queue_free()
