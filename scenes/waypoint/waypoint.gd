tool
extends Position3D

# Hack to ensure a nice editing experience, see _ready function for more details
export(Array, NodePath) var nodes setget set_nodes, get_nodes

func _ready():
	# Load nodes that couldn't be loaded by the editor
	# Reason: The exported data is assigned to the node when opening the scene in the editor,
	# before the node is attached to the tree, therefore it is impossible
	# to translate the node paths to the corresponding nodes
	# 
	# Why don't you just use NodePaths? Because if you rename the node, the path gets invalid and you have to correct it manually
	# Unfortunately godot doesn't provide a way to export Node variables directly, therefore this hack is the best you can do
	#
	# This code is mostly copied from res://scenes/board_logic/node/node.gd
	set_nodes(nodes)
	
	if Engine.editor_hint:
		set_process(true)
	else:
		$EditorLines.queue_free()

func set_nodes(n):
	# Suppress errors on the command line when opening the project the first time
	# The nodes are loaded in the _ready function
	if not has_node(".."):
		nodes = n
		return
	
	if n == null:
		nodes = null
		return
	
	var result = []
	
	for node in n:
		if node != null:
			node = get_node(node)
		result.append(node)
	
	nodes = result
	update()

func get_nodes():
	if nodes == null:
		return null
	
	var result = []
	
	for node in nodes:
		if node != null:
			result.append(get_path_to(node))
		else:
			result.append(null)
	
	return result

func update():
	if Engine.editor_hint:
		$EditorLines.clear()
		$EditorLines.begin(Mesh.PRIMITIVE_LINES)
		for node in nodes:
			if node == null:
				continue
			
			$EditorLines.set_color(Color(0.0, 1.0, 1.0, 1.0))
			var dir = node.translation - self.translation
			if dir.length() == 0:
				continue
			
			var offset = Vector3()
			$EditorLines.add_vertex(offset)
			$EditorLines.add_vertex(dir + offset)
			$EditorLines.add_vertex(dir + offset)
			$EditorLines.add_vertex(dir + offset + (-0.25 * dir.normalized()).rotated(Vector3(0, 1, 0), 0.2617994))
			$EditorLines.add_vertex(dir + offset)
			$EditorLines.add_vertex(dir + offset + (-0.25 * dir.normalized()).rotated(Vector3(0, 1, 0), -0.2617994))
		$EditorLines.end()
