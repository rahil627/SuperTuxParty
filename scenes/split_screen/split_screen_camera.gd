extends Camera

func _process(delta):
	$Viewport/Camera.transform = global_transform
