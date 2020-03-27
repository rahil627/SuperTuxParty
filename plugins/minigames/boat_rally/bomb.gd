extends Spatial

func _ready():
	$Sprite3D.set_as_toplevel(true)
	$Sprite3D.translation.y = 0

func _process(delta):
	self.translation.y -= 9.81 * delta
	if self.translation.y <= 0:
		$Sprite3D.hide()
	else:
		$Sprite3D.material_override.set("albedo_color", Color(1, 1, 1, 1 - max(self.translation.y, 0) / 20.0))
	
	if self.translation.y < -5:
		queue_free()

func _on_Bomb_body_entered(body):
	if body.is_in_group("player") and not body.is_hit:
		body.is_hit = true
		$Mesh.hide()
		$Sprite3D.hide()
		$Particles.emitting = true
		get_parent().set_process(false)
		self.set_process(false)
		yield(get_tree().create_timer(2), "timeout")
		Global.minigame_nolok_loose()
