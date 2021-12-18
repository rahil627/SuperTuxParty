extends RigidBody

export var curve: NodePath

const SPEED := 10.0

var time := 0.0

func update_rotation(up: Vector3, state):
	var forward := self.translation + up.cross(Vector3.RIGHT)
	state.transform = state.transform.looking_at(forward, up)

func _ready():
	var path: Path = get_node(curve)
	var curve := path.curve
	var curve_global_position = Vector3(0, self.translation.y, self.translation.z)
	var curve_local_position = path.transform.affine_inverse() * curve_global_position
	time = curve.get_closest_offset(curve_local_position) - 3.0

	var target := path.transform * curve.interpolate_baked(time)
	var up_vector = path.transform * curve.interpolate_baked_up_vector(time, true) - path.translation

	self.translation.y = target.y
	self.translation.z = target.z
	update_rotation(-up_vector, self)

func _integrate_forces(state: PhysicsDirectBodyState) -> void:
	time -= SPEED * get_parent().direction * state.step
	var path: Path = get_node(curve)
	var curve := path.curve
	var offset = fposmod(time, curve.get_baked_length())

	var target := path.transform * curve.interpolate_baked(offset)
	var up_vector = path.transform * curve.interpolate_baked_up_vector(offset, true) - path.translation
	var translated_target = Vector3(self.translation.x, target.y, target.z)
	state.linear_velocity = (translated_target - self.translation) / state.step
	update_rotation(-up_vector, state)

#func _on_Hurdle_body_entered(body: Node) -> void:
#	if body.is_in_group("players"):
#		body.hit_hurdle()
