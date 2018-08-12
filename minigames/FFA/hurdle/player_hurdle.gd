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
	if Input.is_action_pressed("player" + var2str(player_id) + "_action1") && jump > 0:
		movement = Vector3(0, 5, 0)
	
	movement += GRAVITY * GRAVITY_DIR * delta
	
	move_and_slide(movement, Vector3(0.0, 1.0, 0.0))
	
	jump -= 1
	
	if is_on_floor():
		movement = Vector3()
		jump = JUMP_MAX