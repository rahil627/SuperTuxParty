extends Spatial

func _ready():
	set_as_toplevel(true)
	$AnimationPlayer.play("walk", -1, 0)
