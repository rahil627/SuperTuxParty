extends RigidBody

const JUMP_VELOCITY := 16.5
const BASE_SPEED := 4.0
const PLATFORM_SPEED := 3.0

export(NodePath) var path

enum State {
	IDLE,
	RUNNING,
	JUMP,
	STUNNED
}

var player_id
var is_ai
var ai_difficulty

# The current animation state
var state: int = State.IDLE

# The players movement speed
var speed := BASE_SPEED

# Regulates whether the player can jump
# Is reset when the ground is touched
var on_floor := true


var ai_direction := 0.0
var ai_direction_change := 0.0

var perm_rotation := Vector3()

func _ready():
	$Model.play_animation("idle")
	state = State.IDLE

func face_direction(dir: Vector3, state: PhysicsDirectBodyState):
	if dir.length_squared() > 0.01:
		state.transform = state.transform.looking_at(self.translation - dir, Vector3.UP)

func jump():
	if on_floor:
		$AudioStreamPlayer.play()
		linear_velocity.y = JUMP_VELOCITY
		on_floor = false
		$Model.play_animation("jump")
		self.state = State.JUMP
		return true
	return false

func process_ai(state: PhysicsDirectBodyState):
	ai_direction_change -= state.step
	if ai_direction_change <= 0.0:
		ai_direction = -sign(self.translation.z)
		ai_direction_change += 0.5 + (randf() - 0.5) * 0.1
	if abs(translation.z) > 1.0 and sign(translation.z) == sign(ai_direction):
		ai_direction = 0.0
	var dir = Vector3()
	dir = Vector3(0, 0, ai_direction)
	var v =  speed * dir.normalized() + PLATFORM_SPEED * Vector3(0, 0, get_parent().direction)
	state.linear_velocity.x = v.x 
	state.linear_velocity.z = v.z
	state.linear_velocity += dir * speed
	face_direction(dir, state)
	
	for hurdle in get_tree().get_nodes_in_group("hurdles"):
		if (hurdle.translation - self.translation).length_squared() <= 1.0:
			jump()

func process_player(state: PhysicsDirectBodyState):
	var dir = Vector3(0, 0, 0)
	dir.z += Input.get_action_strength("player{0}_up".format([player_id]))
	dir.z -= Input.get_action_strength("player{0}_down".format([player_id]))
	
	var v =  speed * dir.normalized()
	if on_floor:
		v += PLATFORM_SPEED * Vector3(0, 0, get_parent().direction)
	state.linear_velocity.x = v.x
	state.linear_velocity.z = v.z
	face_direction(dir, state)
	
	if Input.is_action_pressed("player{0}_action1".format([player_id])):
		jump()

	if self.state == State.IDLE and dir.length_squared() > 0.01:
		$Model.play_animation("run")
		self.state = State.RUNNING
	elif self.state == State.RUNNING and dir.length_squared() <= 0.01:
		$Model.play_animation("idle")
		self.state = State.IDLE

func _integrate_forces(state: PhysicsDirectBodyState) -> void:#(delta: float):
	if is_ai:
		process_ai(state)
	else:
		process_player(state)

	if on_floor and self.state == State.JUMP:
		$Model.play_animation("idle")
		self.state = State.IDLE


func _on_Player_body_entered(body: Node) -> void:
	if body.is_in_group("ground"):
		on_floor = true

func _on_Player_body_exited(body: Node) -> void:
	if body.is_in_group("ground"):
		on_floor = false
