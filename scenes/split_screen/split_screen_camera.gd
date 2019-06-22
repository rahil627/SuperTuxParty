extends Camera

func _process(_delta):
	$Viewport/Camera.transform = global_transform
