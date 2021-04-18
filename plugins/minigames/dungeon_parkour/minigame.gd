extends Spatial

var fireball = preload("res://plugins/minigames/dungeon_parkour/fireball.tscn")

func _ready():
	create_fireballs()

func _process(_delta: float):
	$Remaining.text = str(stepify($Timer2.time_left, 0.1))

func create_fireballs():
	var instance = fireball.instance()
	instance.translation = $Fireball2.translation
	add_child(instance)
	
	yield(get_tree().create_timer(0.25), "timeout")
	
	instance = fireball.instance()
	instance.translation = $Fireball3.translation
	add_child(instance)
	
	yield(get_tree().create_timer(0.25), "timeout")
	
	instance = fireball.instance()
	instance.translation = $Fireball1.translation
	add_child(instance)

func _on_Finish_body_entered(_body):
	Global.minigame_nolok_win()

func _on_Timer2_timeout():
	Global.minigame_nolok_loose()
