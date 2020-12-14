extends Control

func _ready():
	yield(get_tree(), "idle_frame")
	$AudioStreamPlayer2.play()
	get_tree().create_timer(4).connect("timeout", $AudioStreamPlayer, "play")
