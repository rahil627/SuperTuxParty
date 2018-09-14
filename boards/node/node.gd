tool
extends Spatial

enum NODE_TYPES {BLUE, RED, GREEN}

# The setter and getter for this variables ensure that the changes are immediately visible to the editor
export(NODE_TYPES) var type = BLUE setget set_type
export var potential_cake = false setget set_cake

# Hack to ensure a nice editing experience, see _ready function for more details
export(Array, NodePath) var next_nodes setget set_next, get_next
export(Array, NodePath) var prev_nodes setget set_prev, get_prev

var next
var prev

var cake = false

# The material for editor rendered linking arrows
var material = SpatialMaterial.new()

# Radius of a node, used for drawing arrows in the editor
const NODE_RADIUS = 1

func _ready():
	# Load nodes that couldn't be loaded by the editor
	# Reason: The exported data is assigned to the node when opening the scene in the editor,
	# before the node is attached to the tree, therefore it is impossible
	# to translate the node paths to the corresponding nodes
	# 
	# Why don't you just use NodePaths? Because if you rename the node, the path gets invalid and you have to correct it manually
	# Unfortunately godot doesn't provide a way to export Node variables directly, therefore this hack is the best you can do
	set_next(next_nodes)
	set_prev(prev_nodes)
	set_material()
	
	if Engine.editor_hint:
		set_process(true)
		
		# search for a previous node if not present (autoconnect)
		# attaches to the previous node in the scene order, if it is the first, it has no effect
		if prev == null:
			var nodes = get_tree().get_nodes_in_group("nodes")
			
			var pos = nodes.find(self)
			if pos > 0:
				if nodes[pos - 1].next == null:
					nodes[pos - 1].next = [self]
				else:
					nodes[pos - 1].next.append(self)
				prev = [nodes[pos - 1]]
	else:
		$EditorLines.queue_free()

# Updates the changes in the editor when potential_cake is changes
func set_cake(enabled):
	potential_cake = enabled
	
	if potential_cake:
		if Engine.editor_hint and has_node("Cake"):
			$Cake.show()
	else:
		if Engine.editor_hint and has_node("Cake"):
			$Cake.hide()

# This function translates the NodePath objects used by the editor to the actual nodes
func set_next(array):
	# Suppress errors on the command line when opening th project the first time
	# The nodes are loaded in the _ready function
	if not has_node(".."):
		next_nodes = array
		return
	
	if array == null:
		next = null
		return
	
	var result = []
	
	for node in array:
		if node != null:
			node = get_node(node)
		result.append(node)
		if node != null:
			if not "prev" in node:
				continue
			if node.prev == null:
				node.prev = [self]
			elif not node.prev.has(self):
				node.prev.append(self)
	
	if next != null:
		for node in next:
			if node != null and not result.has(node):
				node.prev.erase(self)
	
	next = result

# This function translates the Node-references used intern to the NodePaths the editor uses
func get_next():
	if next == null:
		return null
	
	var result = []
	
	for node in next:
		if node != null:
			result.append(get_path_to(node))
		else:
			result.append(null)
	
	return result

# This function translates the NodePath objects used by the editor to the actual nodes
func set_prev(array):
	# Suppress errors on the command line when opening th project the first time
	# The nodes are loaded in the _ready function
	if not has_node(".."):
		prev_nodes = array
		return
	
	if array == null:
		prev = null
		return
	
	var result = []
	
	for node in array:
		if node != null:
			node = get_node(node)
		result.append(node)
		
		if node != null:
			if not "next" in node:
				continue
			if node.next == null:
				node.next = [self]
			elif not node.next.has(self):
				node.next.append(self)
	
	if prev != null:
		for node in prev:
			if node != null and not result.has(node):
				node.next.erase(self)
	
	prev = result

# This function translates the nodes used intern to the NodePaths the editor uses
func get_prev():
	if prev == null:
		return null
	
	var result = []
	
	for node in prev:
		if node != null:
			result.append(get_path_to(node))
		else:
			result.append(null)
	
	return result

# Updates the visual changes in the editor when the type is being changed
func set_type(t):
	type = t
	
	# Check if it has already been added to the tree to prevent errors
	# from flooding the console when opening it in the editor
	if has_node("Model/Cylinder"):
		set_material()

# Helper function to update the material based on the node-type
func set_material():
	match type:
		RED:
			$Model/Cylinder.set_surface_material(0, preload("res://boards/node/node_red_material.tres"))
		GREEN:
			$Model/Cylinder.set_surface_material(0, preload("res://boards/node/node_green_material.tres"))
		BLUE:
			$Model/Cylinder.set_surface_material(0, preload("res://boards/node/node_blue_material.tres"))

func _exit_tree():
	for p in next:
		p.prev.erase(self)
	for p in prev:
		p.next.erase(self)

func _enter_tree():
	add_to_group("nodes")
	set_material()
	
	if next != null:
		for p in next:
			if not p.prev.has(self):
				p.prev.append(self)
	if prev != null:
		for p in prev:
			if not p.next.has(self):
				p.next.append(self)
	
	if potential_cake:
		if Engine.editor_hint == true:
			$Cake.show()
		add_to_group("cake_nodes")
	elif not Engine.editor_hint:
		$Cake.queue_free()
		$EditorLines.queue_free()
	
	# Set up the material for the linking arrows rendered in the editor
	if  Engine.editor_hint:
		material.flags_unshaded = true
		material.flags_use_point_size = true
		material.vertex_color_use_as_albedo = true
		material.flags_vertex_lighting = true
		$EditorLines.set_material_override(material)

const SHOW_NEXT_NODES = 1
const SHOW_PREV_NODES = 2
const SHOW_ALL        = 3

# Renders the linking arrows
func _process(delta):
	if Engine.editor_hint:
		var controllers = get_tree().get_nodes_in_group("Controller")
		var show_linking_type = SHOW_ALL
		if controllers.size() > 0:
			show_linking_type = controllers[0].show_linking_type
		
		$EditorLines.clear()
		$EditorLines.begin(Mesh.PRIMITIVE_LINES)
		if (show_linking_type & SHOW_NEXT_NODES) != 0 and next != null:
			for node in next:
				if node == null:
					continue
				
				$EditorLines.set_color(Color(0.0, 1.0, 1.0, 1.0))
				var dir = node.translation - self.translation
				if dir.length() == 0:
					continue
				
				dir *= (dir.length() - NODE_RADIUS) / dir.length()
				var offset = 0.25 * Vector3(0, 1, 0).cross(dir.normalized())
				$EditorLines.add_vertex(offset)
				$EditorLines.add_vertex(dir + offset)
				$EditorLines.add_vertex(dir + offset)
				$EditorLines.add_vertex(dir + offset + (-0.25 * dir.normalized()).rotated(Vector3(0, 1, 0), 0.2617994))
				$EditorLines.add_vertex(dir + offset)
				$EditorLines.add_vertex(dir + offset + (-0.25 * dir.normalized()).rotated(Vector3(0, 1, 0), -0.2617994))
		if (show_linking_type & SHOW_PREV_NODES) != 0 and prev != null:
			for node in prev:
				if node == null:
					continue
				
				$EditorLines.set_color(Color(1.0, 0.0, 0.5, 1.0))
				var dir = node.translation - self.translation
				if dir.length() == 0:
					continue
				
				dir *= (dir.length() - NODE_RADIUS) / dir.length()
				var offset = 0.25 * Vector3(0, 1, 0).cross(dir.normalized())
				$EditorLines.add_vertex(offset)
				$EditorLines.add_vertex(dir + offset)
				$EditorLines.add_vertex(dir + offset)
				$EditorLines.add_vertex(dir + offset + (-0.25 * dir.normalized()).rotated(Vector3(0, 1, 0), 0.2617994))
				$EditorLines.add_vertex(dir + offset)
				$EditorLines.add_vertex(dir + offset + (-0.25 * dir.normalized()).rotated(Vector3(0, 1, 0), -0.2617994))
		$EditorLines.end()