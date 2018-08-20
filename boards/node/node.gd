tool
extends StaticBody

export var red = false
export var green = false
export var potential_cake = false

var cake = false

func _enter_tree():
	add_to_group("nodes")
	if red:
		$"Model/Cylinder".set_surface_material(0, preload("res://boards/node/node_red_material.tres"))
	elif green:
		$"Model/Cylinder".set_surface_material(0, preload("res://boards/node/node_green_material.tres"))
	else:
		$"Model/Cylinder".set_surface_material(0, preload("res://boards/node/node_blue_material.tres"))
	
	if potential_cake:
		if Engine.editor_hint == true:
			$Cake.show()
		add_to_group("cake_nodes")
	elif Engine.editor_hint == false:
		$Cake.queue_free()