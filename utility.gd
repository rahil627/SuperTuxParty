extends Node

func apply_nextpass_material(material, node):
	if node is MeshInstance:
		var mat = node.get_surface_material(0)
		var i = 0
		while mat != null:
			while mat.next_pass != null:
				mat = mat.next_pass
			mat.next_pass = material
			i += 1
			mat = node.get_surface_material(i)
	
	for child in node.get_children():
		apply_nextpass_material(material, child)