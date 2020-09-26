extends KinematicBody

export(bool) var is_solo_player = false

const GRAVITY = Vector3(0, -9.81, 0)
const SPEED = 4
const GROUND_BOX := AABB(Vector3(-2.5, 0, -5.5), Vector3(5, 4, 5))

var is_ai: bool
var ai_difficulty: int
var player_id: int

enum STATE {
	IDLE,
	RUNNING,
	JUMP,
	DEAD
}

const FIRE_COOLDOWN_TIME := 0.85
var fire_cooldown := 0.5

onready var MAX_DIR_CHANGE_TIME := 1.0 if is_solo_player else 2.0
onready var MIN_DIR_CHANGE_TIME := 0.5 if is_solo_player else 1.0
const MIN_JUMP_TIME := 0.5
const MAX_JUMP_TIME := 1.5

var ai_running_dir := Vector3()
var ai_time_dir_change := 0.0
var ai_jump_timer := rand_range(MIN_JUMP_TIME, MAX_JUMP_TIME)

var stun_duration := 0.0

var state: int = STATE.IDLE

var movement := Vector3()

func fire():
	if fire_cooldown <= 0:
		var ball := preload("res://plugins/minigames/bowling/ball.tscn").instance()
		ball.translation = translation + Vector3(0, 0.25, -2)
		get_parent().add_child(ball)
		
		fire_cooldown = FIRE_COOLDOWN_TIME

func solo_player(delta: float):
	if not is_ai:
		if Input.is_action_just_pressed("player%d_action2" % player_id):
			fire()
		var right_strength := Input.get_action_strength("player%d_right" % player_id)
		var left_strength := Input.get_action_strength("player%d_left" % player_id)
		self.translation.x += (right_strength - left_strength) * SPEED * delta
	else:
		fire()
		if self.translation.x <= -2.7 or self.translation. x >= 2.7:
			ai_running_dir = -ai_running_dir
		ai_time_dir_change -= delta
		if ai_time_dir_change <= 0:
			if randi() % 2 == 0:
				ai_running_dir = Vector3(1, 0, 0)
			else:
				ai_running_dir = Vector3(-1, 0, 0)
			ai_time_dir_change = rand_range(MIN_DIR_CHANGE_TIME, MAX_DIR_CHANGE_TIME)
		self.translation += ai_running_dir * SPEED * delta

	self.translation.x = clamp(self.translation.x, -2.75, 2.75)

func group_player(delta: float):
	var dir = Vector3()
	
	if not is_ai and stun_duration == 0:
		dir.x = Input.get_action_strength("player%d_right" % player_id) - Input.get_action_strength("player%d_left" % player_id)
		dir.z = Input.get_action_strength("player%d_down" % player_id) - Input.get_action_strength("player%d_up" % player_id)
		
		if Input.is_action_pressed("player%d_action1" % player_id) and is_on_floor():
			if state != STATE.JUMP:
				$Model.play_animation("jump")
				state = STATE.JUMP
			movement = Vector3(0, 4, 0)
	elif stun_duration == 0:
		ai_time_dir_change -= delta
		if ai_time_dir_change <= 0:
			ai_running_dir = Vector3(1, 0, 0).rotated(Vector3(0, 1, 0), rand_range(-PI, PI))
			ai_time_dir_change = rand_range(MIN_DIR_CHANGE_TIME, MAX_DIR_CHANGE_TIME)
		
		var test_pos = translation + ai_running_dir * delta
		if not GROUND_BOX.has_point(Vector3(test_pos.x, 0, test_pos.z)):
			ai_running_dir = -ai_running_dir
		
		if is_on_floor():
			ai_jump_timer -= delta
			if ai_jump_timer <= 0:
				ai_jump_timer = rand_range(MIN_JUMP_TIME, MAX_JUMP_TIME)
				if state != STATE.JUMP:
					$Model.play_animation("jump")
					state = STATE.JUMP
				movement = Vector3(0, 4, 0)
		
		dir = ai_running_dir
	
	if translation.y < -2:
		knockout(Vector3())
		queue_free()
	
	if dir.length() > 0:
		if state == STATE.IDLE:
			$Model.play_animation("run")
			state = STATE.RUNNING
		dir = dir.normalized()
		if not is_solo_player:
			rotation = Vector3(0, atan2(dir.x, dir.z), 0)
	elif stun_duration == 0:
		if state == STATE.RUNNING:
			$Model.play_animation("idle")
			state = STATE.IDLE
	
	movement += GRAVITY * delta
	
	move_and_slide(movement + dir * SPEED, Vector3(0, 1, 0))
	
	if is_on_floor():
		movement = Vector3()
		if state == STATE.JUMP:
			$Model.play_animation("idle")
			state = STATE.IDLE

func _physics_process(delta: float):
	fire_cooldown -= delta
	stun_duration = max(stun_duration - delta, 0)
	if is_solo_player:
		solo_player(delta)
	elif state != STATE.DEAD:
		group_player(delta)
	else:
		movement += GRAVITY * delta
		
		# Knock out all players that are hit by a knocked out player
		var collision = move_and_collide(movement * delta)
		
		if collision != null:
			var object = collision.collider
			if object.is_in_group("players") or object.is_in_group("box"):
				object.knockout(movement)

func knockout(mov: Vector3):
	if state != STATE.DEAD:
		state = STATE.DEAD
		get_parent().knockout()
		movement = mov

func stun(duration: float):
	$Model.play_animation("stun")
	self.stun_duration = max(self.stun_duration, duration)

