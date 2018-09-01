extends KinematicBody

const GRAVITY = 9.8 # Acceleration of gravity
const GRAVITY_DIR = Vector3(0, -1, 0) # Direction of gravity
const JUMP_MAX = 10

var player_id = 1
var jump = JUMP_MAX
var movement = Vector3()

func _init():
	add_to_group("players")

func _physics_process(delta):
	if not $"/root/Global".players[player_id - 1].is_ai and Input.is_action_pressed("player" + var2str(player_id) + "_action1") and jump > 0:
		movement = Vector3(0, 5, 0)
	elif $"/root/Global".players[player_id - 1].is_ai and jump > 0:
		for hurdle in get_tree().get_nodes_in_group("hurdles"):
			var dir = hurdle.translation - self.translation
			if dir.length() < 5 and dir.angle_to(Vector3(0, 0, 1)) < PI/4:
				movement = Vector3(0, 5, 0)
	
	movement += GRAVITY * GRAVITY_DIR * delta
	
	move_and_slide(movement, Vector3(0.0, 1.0, 0.0))
	
	jump -= 1
	
	if is_on_floor():
		movement = Vector3()
		jump = JUMP_MAX