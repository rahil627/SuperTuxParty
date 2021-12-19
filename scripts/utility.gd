extends Node

func _nextpass_apply_mesh(material: Material, mesh: Mesh) -> void:
	for i in range(mesh.get_surface_count()):
		var mat: Material = mesh.surface_get_material(i)
		if not mat:
			continue
		while not mat.next_pass in [null, material]:
			mat = mat.next_pass
		mat.next_pass = material

func apply_nextpass_material(material: Material, node: Node) -> void:
	if node is MeshInstance:
		_nextpass_apply_mesh(material, node.mesh)
		for i in range(node.get_surface_material_count()):
			var mat: Material = node.get_surface_material(i)
			if not mat:
				continue
			while not mat.next_pass in [null, material]:
				mat = mat.next_pass
			mat.next_pass = material

	for child in node.get_children():
		apply_nextpass_material(material, child)

func _nextpass_remove_mesh(material: Material, mesh: Mesh) -> void:
	for i in range(mesh.get_surface_count()):
		var mat: Material = mesh.surface_get_material(i)
		if not mat:
			continue
		while not mat.next_pass in [null, material]:
			mat = mat.next_pass
		if mat.next_pass == material:
			mat.next_pass = material.next_pass

func remove_nextpass_material(material: Material, node: Node) -> void:
	if node is MeshInstance:
		_nextpass_remove_mesh(material, node.mesh)
		for i in range(node.get_surface_material_count()):
			var mat: Material = node.get_surface_material(i)
			if not mat:
				continue
			while not mat.next_pass in [null, material]:
				mat = mat.next_pass
			if mat.next_pass == material:
				mat.next_pass = material.next_pass

	for child in node.get_children():
		remove_nextpass_material(material, child)

func _shape_to_aabb(s: Shape) -> AABB:
	if s is BoxShape:
		return AABB(-0.5 * s.extents, s.extents)
	elif s is SphereShape:
		var v := Vector3(s.radius, s.radius, s.radius)
		return AABB(-0.5 * v, v)
	elif s is CylinderShape:
		var v := Vector3(s.radius, s.height, s.radius)
		return AABB(-0.5 * v, v)
	elif s is CapsuleShape:
		var v := Vector3(s.radius, s.height + 2 * s.radius, s.radius)
		return AABB(-0.5 * v, v)
	elif s is ConvexPolygonShape:
		var begin := Vector3()
		var end := Vector3()

		for point in s.points:
			begin.x = min(point.x, begin.x)
			begin.y = min(point.y, begin.y)
			begin.z = min(point.z, begin.z)

			end.x = max(point.x, end.x)
			end.y = max(point.y, end.y)
			end.z = max(point.z, end.z)

		return AABB(begin, end - begin)
	elif s is ConcavePolygonShape:
		var begin := Vector3()
		var end := Vector3()

		for point in s.get_faces():
			begin.x = min(point.x, begin.x)
			begin.y = min(point.y, begin.y)
			begin.z = min(point.z, begin.z)

			end.x = max(point.x, end.x)
			end.y = max(point.y, end.y)
			end.z = max(point.z, end.z)

		return AABB(begin, end - begin)

	push_error("Unexpected Shape type in get_aabb_from_shape: %s" %\
			s.get_class())
	return AABB()

func get_aabb_from_shape(s: Shape, transform := Transform()) -> AABB:
	return transform.xform(_shape_to_aabb(s))

func error_code_to_string(error: int) -> String:
	match error:
		OK:
			return "OK"
		FAILED:
			return "Generic Error"
		ERR_UNAVAILABLE:
			return "Resource is unavailable"
		ERR_UNCONFIGURED:
			return "Resource is unconfigured"
		ERR_UNAUTHORIZED:
			return "Unauthorized"
		ERR_PARAMETER_RANGE_ERROR:
			return "Parameter range error"
		ERR_OUT_OF_MEMORY:
			return "Out of memory"
		ERR_FILE_NOT_FOUND:
			return "File not found"
		ERR_FILE_BAD_DRIVE:
			return "Invalid drive"
		ERR_FILE_BAD_PATH:
			return "Invalid path"
		ERR_FILE_NO_PERMISSION:
			return "No permission"
		ERR_FILE_ALREADY_IN_USE:
			return "File already in use"
		ERR_FILE_CANT_OPEN:
			return "Can't open file"
		ERR_FILE_CANT_WRITE:
			return "Can't write to file"
		ERR_FILE_CANT_READ:
			return "Can't read from file"
		ERR_FILE_UNRECOGNIZED:
			return "File unrecognized"
		ERR_FILE_CORRUPT:
			return "File corrupt"
		ERR_FILE_MISSING_DEPENDENCIES:
			return "Missing dependencies"
		ERR_FILE_EOF:
			return "Unexpected end of file"
		ERR_CANT_OPEN:
			return "Can't open"
		ERR_CANT_CREATE:
			return "Can't create"
		ERR_PARSE_ERROR:
			return "Parse error"
		ERR_QUERY_FAILED:
			return "Query failed"
		ERR_ALREADY_IN_USE:
			return "Already in use"
		ERR_LOCKED:
			return "Locked"
		ERR_TIMEOUT:
			return "Timeout"
		ERR_CANT_ACQUIRE_RESOURCE:
			return "Can't acquire resource"
		ERR_INVALID_DATA:
			return "Invalid data"
		ERR_INVALID_PARAMETER:
			return "Invalid parameter"
		ERR_ALREADY_EXISTS:
			return "Already exists"
		ERR_DOES_NOT_EXIST:
			return "Does not exist"
		ERR_DATABASE_CANT_READ:
			return "Can't read from database"
		ERR_DATABASE_CANT_WRITE:
			return "Can't write to database"
		ERR_COMPILATION_FAILED:
			return "Compilaton failed"
		ERR_METHOD_NOT_FOUND:
			return "Method not found"
		ERR_LINK_FAILED:
			return "Linking failed"
		ERR_SCRIPT_FAILED:
			return "Script failed"
		ERR_CYCLIC_LINK:
			return "Import cycle"
		ERR_BUSY:
			return "Resource Busy"
		ERR_HELP:
			return "Help"
		ERR_BUG:
			return "Bug"
		_:
			return "Unknown"
