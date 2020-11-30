tool
extends Spatial
class_name NodeBoard

enum NODE_TYPES {
	BLUE,
	RED,
	GREEN,
	YELLOW,
	SHOP,
	NOLOK,
	GNU
}

export(bool) var _visible = true setget set_hidden
# The setter and getter for this variables ensure that the changes are
# immediately visible to the editor.
export(NODE_TYPES) var type: int = NODE_TYPES.BLUE setget set_type
export var potential_cake := false setget set_cake

# Hack to ensure a nice editing experience, see _ready function for more
# details.
export(Array, NodePath) var next_nodes setget set_next, get_next
export(Array, NodePath) var prev_nodes setget set_prev, get_prev

# Settings for shop node.
const MAX_STORE_SIZE = 6

# "const" properties are not valid in export declarations, therefore the
# content MAX_STORE_SIZE is repeated as upper bound here.
export(int, 1, 6) var amount_of_items_sold = 8
export(Array, String, FILE, "*.gd") var custom_items = []

var next
var prev

var cake := false setget set_active_cake

# An item that was placed onto this node.
var trap: Item setget set_trap
var trap_player = null

# The material for editor rendered linking arrows.
var material := SpatialMaterial.new()

# Radius of a node, used for drawing arrows in the editor.
const NODE_RADIUS = 1

func set_hidden(v: bool):
	_visible = v
	$Model.visible = v

func is_visible_space() -> bool:
	return _visible

func _ready() -> void:
	# Load nodes that couldn't be loaded by the editor.
	# Reason: The exported data is assigned to the node when opening the scene
	# in the editor, before the node is attached to the tree, therefore it is
	# impossible to translate the node paths to the corresponding nodes.
	#
	# Why don't you just use NodePaths? Because if you rename the node, the
	# path gets invalid and you have to correct it manually.
	# Unfortunately Godot doesn't provide a way to export Node variables
	# directly, therefore this hack is the best you can do.
	set_next(next_nodes)
	set_prev(prev_nodes)
	set_material()

	if Engine.editor_hint:
		set_process(true)

		# Search for a previous node if not present (autoconnect).
		# Attaches to the previous node in the scene order, if it is the first,
		# it has no effect.
		if prev == null:
			var nodes: Array = get_tree().get_nodes_in_group("nodes")

			var pos: int = nodes.find(self)
			if pos > 0:
				if nodes[pos - 1].next == null:
					nodes[pos - 1].next = [self]
				else:
					nodes[pos - 1].next.append(self)
				prev = [nodes[pos - 1]]
	else:
		$EditorLines.queue_free()
		# Only the node model should be rotated/scaled.
		# Because it's an instanced scene, only modifications to the root model
		# are saved.
		# Therefore we can't just forward the transformation in the editor.
		# That's why we do it here.
		$Model.transform.basis = self.transform.basis * $Model.transform.basis
		self.transform.basis = Basis()

# Updates the changes in the editor when potential_cake is changes
func set_cake(enabled: bool) -> void:
	potential_cake = enabled

	if potential_cake:
		if Engine.editor_hint and has_node("Cake"):
			$Cake.show()
	else:
		if Engine.editor_hint and has_node("Cake"):
			$Cake.hide()

func play_cake_collection_animation():
	$Cake/AnimationPlayer.play("collect")
	yield($Cake/AnimationPlayer, "animation_finished")

# Sets wether this node is the currently active cake spot
func set_active_cake(enabled: bool) -> void:
	cake = enabled
	if cake:
		$Cake.show()
		$Cake/AnimationPlayer.play_backwards("collect")
		$Cake/AnimationPlayer.queue("float")
	else:
		$Cake.hide()

# This function translates the NodePath objects used by the editor to the
# actual nodes.
func set_next(array) -> void:
	# Suppress errors on the command line when opening th project the first
	# time the nodes are loaded in the _ready function.
	if not has_node(".."):
		next_nodes = array
		return

	if array == null:
		next = null
		return

	var result := []

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

# This function translates the Node-references used intern to the NodePaths the
# editor uses.
func get_next():
	if next == null:
		return

	var result := []

	for node in next:
		if node != null:
			result.append(get_path_to(node))
		else:
			result.append(null)

	return result

# This function translates the NodePath objects used by the editor to the
# actual nodes.
func set_prev(array):
	# Suppress errors on the command line when opening th project the first time
	# The nodes are loaded in the _ready function.
	if not has_node(".."):
		prev_nodes = array
		return

	if array == null:
		prev = null
		return

	var result := []

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

# This function translates the nodes used intern to the NodePaths the editor
# uses.
func get_prev():
	if prev == null:
		return

	var result := []

	for node in prev:
		if node != null:
			result.append(get_path_to(node))
		else:
			result.append(null)

	return result

# Updates the visual changes in the editor when the type is being changed.
func set_type(t) -> void:
	if t != null:
		type = t

	# Check if it has already been added to the tree to prevent errors from
	# flooding the console when opening it in the editor.
	if has_node("Model/Cylinder"):
		set_material()

func set_trap(item: Item) -> void:
	trap = item

	set_material()

	if item == null:
		remove_from_group("trap")
	else:
		add_to_group("trap")

# Helper function to update the material based on the node-type.
func set_material() -> void:
	if trap != null:
		$Model/Cylinder.set_surface_material(0, trap.material)
		return

	match type:
		NODE_TYPES.RED:
			$Model/Cylinder.set_surface_material(0, preload(
					"res://scenes/board_logic/node/material/" +
					"node_red_material.tres"))
		NODE_TYPES.GREEN:
			$Model/Cylinder.set_surface_material(0, preload(
			"res://scenes/board_logic/node/material/" +
			"node_green_material.tres"))
		NODE_TYPES.BLUE:
			$Model/Cylinder.set_surface_material(0, preload(
			"res://scenes/board_logic/node/material/" +
			"node_blue_material.tres"))
		NODE_TYPES.YELLOW:
			$Model/Cylinder.set_surface_material(0, preload(
			"res://scenes/board_logic/node/material/" +
			"node_yellow_material.tres"))
		NODE_TYPES.SHOP:
			$Model/Cylinder.set_surface_material(0, preload(
			"res://scenes/board_logic/node/material/" +
			"node_purple_material.tres"))
		NODE_TYPES.NOLOK:
			$Model/Cylinder.set_surface_material(0, preload(
			"res://scenes/board_logic/node/material/" +
			"node_nolok_material.tres"))
		NODE_TYPES.GNU:
			$Model/Cylinder.set_surface_material(0, preload(
			"res://scenes/board_logic/node/material/" +
			"node_gnu_material.tres"))

func _exit_tree() -> void:
	for p in next:
		p.prev.erase(self)
	for p in prev:
		p.next.erase(self)

func _enter_tree() -> void:
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
		else:
			add_to_group("cake_nodes")
	elif not Engine.editor_hint:
		$Cake.queue_free()
		$EditorLines.queue_free()

const SHOW_NEXT_NODES = 1
const SHOW_PREV_NODES = 2
const SHOW_ALL = 3

# Renders the linking arrows.
func _process(_delta: float) -> void:
	if Engine.editor_hint:
		# Only the node model should be rotated/scaled
		# Because the root node is being edited, we can't just forward
		# Those transformation to the node model and keep the rest normal.
		# If we'd try, it won't be saved as it's an instanced scene
		var inverse_rotation = -self.transform.basis.get_euler()
		var inverse_scale = self.scale.inverse()
		$Cake.rotation = inverse_rotation
		$Cake.scale = inverse_scale
		$EditorLines.rotation = inverse_rotation
		$EditorLines.scale = inverse_scale
		var controllers: Array = get_tree().get_nodes_in_group("Controller")
		var show_linking_type: int = SHOW_ALL
		if controllers.size() > 0:
			show_linking_type = controllers[0].show_linking_type

		$EditorLines.clear()
		$EditorLines.begin(Mesh.PRIMITIVE_LINES)
		if (show_linking_type & SHOW_NEXT_NODES) != 0 and next != null:
			for node in next:
				if node == null:
					continue

				$EditorLines.set_color(Color(0.0, 1.0, 1.0, 1.0))
				var dir: Vector3 = node.translation - self.translation
				if dir.length() == 0:
					continue

				var offset: Vector3 =\
						0.25 * Vector3(0, 1, 0).cross(dir.normalized())
				dir *= (dir.length() - 2*NODE_RADIUS) / dir.length()
				offset += dir.normalized() * NODE_RADIUS
				$EditorLines.add_vertex(offset)
				$EditorLines.add_vertex(dir + offset)
				$EditorLines.add_vertex(dir + offset)
				$EditorLines.add_vertex(dir + offset +
						(-0.25 * dir.normalized()).\
						rotated(Vector3(0, 1, 0), 0.2617994))
				$EditorLines.add_vertex(dir + offset)
				$EditorLines.add_vertex(dir + offset +
						(-0.25 * dir.normalized()).\
						rotated(Vector3(0, 1, 0), -0.2617994))
		if (show_linking_type & SHOW_PREV_NODES) != 0 and prev != null:
			for node in prev:
				if node == null:
					continue

				$EditorLines.set_color(Color(1.0, 0.0, 0.5, 1.0))
				var dir = node.translation - self.translation
				if dir.length() == 0:
					continue

				var offset = 0.25 * Vector3(0, 1, 0).cross(dir.normalized())
				dir *= (dir.length() - 2*NODE_RADIUS) / dir.length()
				offset += dir.normalized() * NODE_RADIUS
				$EditorLines.add_vertex(offset)
				$EditorLines.add_vertex(dir + offset)
				$EditorLines.add_vertex(dir + offset)
				$EditorLines.add_vertex(dir + offset +
						(-0.25 * dir.normalized()).\
						rotated(Vector3(0, 1, 0), 0.2617994))
				$EditorLines.add_vertex(dir + offset)
				$EditorLines.add_vertex(dir + offset +
						(-0.25 * dir.normalized()).\
						rotated(Vector3(0, 1, 0), -0.2617994))

		$EditorLines.end()
