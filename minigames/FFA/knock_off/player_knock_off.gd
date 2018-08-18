extends RigidBody

var player_id = 0
var accel = 15

func _ready():
	$Model.set_as_toplevel(true)
	add_to_group("players")

func _process(delta):
	var dir = Vector3()
	
	$Model.translation = self.translation + Vector3(0, 0.5, 0)
	
	if Input.is_action_pressed("player" + var2str(player_id) + "_up"):
		dir.x -= accel * delta
	if Input.is_action_pressed("player" + var2str(player_id) + "_down"):
		dir.x += accel * delta
	if Input.is_action_pressed("player" + var2str(player_id) + "_left"):
		dir.z += accel * delta
	if Input.is_action_pressed("player" + var2str(player_id) + "_right"):
		dir.z -= accel * delta
	
	dir = dir.normalized()
	
	if angular_velocity.length() < 6 && dir.length() > 0:
		angular_velocity += dir * accel * delta
