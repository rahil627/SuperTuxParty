extends Control

func _process(_delta):
	var progress = Global.get_loader_progress()
	$CenterContainer/VBoxContainer/ProgressBar.max_value = progress[1]
	$CenterContainer/VBoxContainer/ProgressBar.value = progress[0]
	
	if progress[0] == progress[1]:
		Global.call_deferred("change_scene")
