extends KinematicBody

const GRAVITY = 9.8; # Acceleration of gravity
const GRAVITY_DIR = Vector3(0, -1, 0); # Direction of gravity

var player_id = 0;
var gravity = 0; # Accumulated speed
var space = 1; # Space on the board the player is on
var cookies = 0;
var cakes = 0;

func _ready():
	add_to_group("players");

func _physics_process(delta):
	gravity += GRAVITY * delta;
	move_and_slide(gravity * GRAVITY_DIR, Vector3(0, 1, 0));
	if is_on_floor():
		gravity = 0;