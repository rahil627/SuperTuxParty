tool
extends Control

func _ready():
	if Engine.editor_hint:
		get_parent().add_to_group("Controller")