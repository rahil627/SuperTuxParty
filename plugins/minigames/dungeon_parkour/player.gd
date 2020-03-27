extends KinematicBody

const SPEED = 5
const JUMP_POWER = 8
const GRAVITY = 18

enum State {
	IDLE,
	RUN,
	JUMP
}

var player_id: int
var is_ai: bool

var acceleration := Vector3(0, 0, 0)
var state = State.IDLE

var ai_current_waypoint: Spatial = null
var ai_rand_start: float

func _ready():
	$CameraTracker.set_as_toplevel(true)
	$Model/AnimationPlayer.play("idle")
	
	if is_ai:
		ai_current_waypoint = $"../Ground/Waypoint"
		ai_rand_start = randf() * 2

func calc_movement(previous: float, next: float) -> float:
	if is_on_floor():
		return next
	elif sign(previous) == sign(next):
		return clamp(next, min(previous, 0), max(previous, 0))
	else:
		return previous * 0.9

func _process(delta):
	ai_rand_start -= delta
	if ai_rand_start > 0:
		return
	
	var jump = false
	if not is_ai:
		acceleration.x = calc_movement(acceleration.x, (Input.get_action_strength("player%d_right" % player_id) - Input.get_action_strength("player%d_left" % player_id)) * SPEED)
		acceleration.z = calc_movement(acceleration.z, (Input.get_action_strength("player%d_down" % player_id) - Input.get_action_strength("player%d_up" % player_id)) * SPEED)
		jump = Input.is_action_pressed("player%d_action1" % player_id)
	else:
		var dir: Vector3 = ai_current_waypoint.global_transform.origin - translation
		dir.y = 0
		
		if dir.length() < randf() * 0.5:
			jump = true
			ai_current_waypoint = ai_current_waypoint.get_node(ai_current_waypoint.get_nodes()[0])
		
		if abs(dir.x) < 0.05:
			dir.x = 0
		if abs(dir.z) < 0.05:
			dir.z = 0
		
		if get_floor_velocity().length() < 0.1:
			dir = dir.normalized()
			dir.x = dir.x * SPEED
			dir.z = dir.z * SPEED
			acceleration.x = dir.x
			acceleration.z = dir.z
		else:
			acceleration.x = 0
			acceleration.z = 0

	if acceleration.x or acceleration.z:
		if state == State.IDLE:
			$Model/AnimationPlayer.play("run")
			state = State.RUN
		$Model.rotation.y = atan2(acceleration.x, acceleration.z)
	elif state == State.RUN:
		$Model/AnimationPlayer.play("idle")
		state = State.IDLE
	
	if is_on_floor():
		if state == State.JUMP:
			if acceleration.x:
				$Model/AnimationPlayer.play("run")
				state = State.RUN
			else:
				$Model/AnimationPlayer.play("idle")
				state = State.IDLE
		else:
			acceleration.y = 0
			if jump:
				acceleration.y = JUMP_POWER
				$Model/AnimationPlayer.play("jump")
				state = State.JUMP
	acceleration.y -= GRAVITY * delta
	
	move_and_slide(acceleration + get_floor_velocity() * delta, Vector3(0, 1, 0), true)
	
	$CameraTracker.translation.x = self.translation.x
	$CameraTracker.translation.z = self.translation.z
	
	if translation.y < -5:
		Global.minigame_nolok_loose()
