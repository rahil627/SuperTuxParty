extends Spatial

func _process(delta):
	self.translation.z += 10 * delta

func _on_Area_body_entered(_body):
	Global.minigame_nolok_loose()
