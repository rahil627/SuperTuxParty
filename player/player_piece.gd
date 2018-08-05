extends KinematicBody

const GRAVITY = 9.8;
const GRAVITY_DIR = Vector3(0, -1, 0);

var gravity = 0;
var space = 1;
var cookies = 0;
var cakes = 0;

func _physics_process(delta):
	gravity += GRAVITY * delta;
	move_and_slide(gravity * GRAVITY_DIR, Vector3(0, 1, 0));
	if is_on_floor():
		gravity = 0;