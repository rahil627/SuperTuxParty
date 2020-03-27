extends Spatial

var fireball = preload("res://plugins/minigames/dungeon_parcour/fireball.tscn")

func _ready():
	create_fireballs()

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
