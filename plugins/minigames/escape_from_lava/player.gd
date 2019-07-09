extends KinematicBody

const SPEED = 4
const GRAVITY = 9.8
const GRAVITY_DIR = Vector3(0, -1, 0)

var player_id
var is_ai

var has_finished

var movement = Vector3()

onready var ai_waypoint = get_node("../Navigation/Waypoint")

enum STATE {
	IDLE,
	RUNNING,
	DEAD
}

var state = STATE.IDLE

func _ready():
	$Model/AnimationPlayer.play("idle")

func _process(delta):
	var dir = Vector3()
	if not has_finished:
		if not is_ai and state != STATE.DEAD:
			dir.x = Input.get_action_strength("player%d_left" % player_id) - Input.get_action_strength("player%d_right" % player_id)
			dir.z = Input.get_action_strength("player%d_up" % player_id) - Input.get_action_strength("player%d_down" % player_id)
		elif is_ai and state != STATE.DEAD:
			dir = ai_waypoint.translation - self.translation
			dir = Vector3(dir.x, 0, dir.z)
			
			if dir.length_squared() < 0.1 and ai_waypoint.nodes and ai_waypoint.nodes.size() > 0:
				var index = randi() % ai_waypoint.nodes.size()
				ai_waypoint = ai_waypoint.get_node(ai_waypoint.nodes[index])
	
	if dir.length_squared() > 0:
		dir = dir.normalized()
		rotation.y = atan2(dir.x, dir.z)
		if state == STATE.IDLE:
			state = STATE.RUNNING
			$Model/AnimationPlayer.play("run")
	elif dir.length_squared() == 0 and state == STATE.RUNNING:
		state = STATE.IDLE
		$Model/AnimationPlayer.play("idle")
	
	movement += GRAVITY_DIR * GRAVITY * delta
	if state != STATE.DEAD:
		move_and_slide(movement + dir * SPEED, Vector3(0, 1, 0))
	
	if is_on_floor():
		movement = Vector3()

func die():
	state = STATE.DEAD
	$Model/AnimationPlayer.play("idle")

func is_dead():
	return state == STATE.DEAD
