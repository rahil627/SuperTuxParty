extends RigidBody

var player_id = 0
var accel = 15

func _ready():
	$Model.set_as_toplevel(true)
	add_to_group("players")

func _process(delta):
	$Model.translation = self.translation + Vector3(0, 1, 0);
	if (Input.is_action_pressed("player" + var2str(player_id) + "_up") && angular_velocity.x > -4):
		angular_velocity += Vector3(-accel * delta, 0, 0)
	if (Input.is_action_pressed("player" + var2str(player_id) + "_down") && angular_velocity.x < 4):
		angular_velocity += Vector3(accel * delta, 0, 0)
	if (Input.is_action_pressed("player" + var2str(player_id) + "_left") && angular_velocity.z < 4):
		angular_velocity += Vector3(0, 0, accel * delta)
	if (Input.is_action_pressed("player" + var2str(player_id) + "_right") && angular_velocity.z > -4):
		angular_velocity += Vector3(0, 0, -accel * delta)