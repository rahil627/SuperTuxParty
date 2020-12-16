extends RigidBody

const BOMB := preload("res://plugins/minigames/boat_rally/bomb.tscn")
const MAX_SPEED := 10.0

var position: Vector3

var countdown := 1.0

var is_hit := false

func _integrate_forces(state):
	if is_hit:
		state.linear_velocity = Vector3()
		state.angular_velocity = Vector3()
	
	if state.linear_velocity.length() > MAX_SPEED:
		state.linear_velocity = state.linear_velocity.normalized() * MAX_SPEED
	if rotation_degrees.y < -45:
		rotation_degrees.y = -45
		state.angular_velocity = Vector3(0, 1, 0)
	elif rotation_degrees.y > 45:
		rotation_degrees.y = 45
		state.angular_velocity = Vector3(0, -1, 0)

func _ready():
	$Ground.set_as_toplevel(true)

func fire(pos: Vector3, dir: Vector3) -> bool:
	if not is_hit:
		self.apply_impulse(pos, dir)
		return true
	return false

func _process(delta):
	$"Ground/Scene Root2".translation.z = self.translation.z + 20
	$"Ground/Scene Root3".translation.z = self.translation.z + 40
	countdown -= delta
	if countdown <= 0 and translation.z <= 85:
		for _i in range(4):
			var bomb = BOMB.instance()
			bomb.translation = Vector3((randf() - 0.5) * 16, 20, 10 + randf() * 10 + translation.z)
			$Ground.add_child(bomb)
			bomb = BOMB.instance()
			bomb.translation = Vector3((randf() - 0.5) * 16, 20, randf() * 5 + translation.z)
			$Ground.add_child(bomb)
		$AudioStreamPlayer.play()
		countdown = 4

func _on_Area_body_entered(body):
	if body.is_in_group("player"):
		Global.minigame_nolok_win()
