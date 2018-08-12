tool
extends StaticBody

export var red = false

func _enter_tree():
	add_to_group("nodes")
	if red:
		print("red")
		$"Model/Cylinder".set_surface_material(0, preload("res://boards/node/node_red_material.tres"))
	else:
		$"Model/Cylinder".set_surface_material(0, preload("res://boards/node/node_blue_material.tres"))
