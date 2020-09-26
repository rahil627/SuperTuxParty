extends KinematicBody

const GRAVITY := Vector3(0, -9.81, 0)
var movement := Vector3(0, -4, 0)

var is_falling := true

func _ready():
	$Sprite3D.set_as_toplevel(true)
	$Sprite3D.translation.y = 0.25

func _physics_process(delta: float):
	movement += GRAVITY * delta
	
	var collision := move_and_collide(movement * delta)
	if is_falling:
		$Sprite3D.modulate.a = 1 - clamp((self.translation.y - 0.5) / 5, 0, 0.8)
	
	if collision != null and is_falling:
		is_falling = false
		$Sprite3D.modulate.a = 0
		var object = collision.collider
		if object.is_in_group("players"):
			object.stun(1)
			var knockback_dir = object.translation - self.translation
			if knockback_dir.length_squared() <= 1e-9:
				knockback_dir = Vector3(0, 0, -1)
			else:
				knockback_dir = knockback_dir.normalized()
			object.translation -= knockback_dir * delta * 5
		elif object.is_in_group("box"):
			object.knockout(Vector3())

func knockout(_movement: Vector3):
	$AnimationPlayer.play("destroy")

func _on_AnimationPlayer_animation_finished(_anim):
	queue_free()
