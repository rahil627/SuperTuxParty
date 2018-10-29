extends KinematicBody

export(bool) var is_solo_player = false

const GRAVITY = Vector3(0, -9.81, 0)
const SPEED = 4

const ground_box = AABB(Vector3(-3, -1, -5), Vector3(6, 2, 4))
const solo_ground_box = AABB(Vector3(-3, -0.25, 3), Vector3(6, 0.5, 2))

var is_ai
var player_id

enum {
	PAUSED,
	
	IDLE,
	RUNNING,
	JUMP,
	DEAD
}

const FIRE_COOLDOWN_TIME = 1
var fire_cooldown = 0.5

const MAX_DIR_CHANGE_TIME = 2
const MIN_DIR_CHANGE_TIME = 1
const MIN_JUMP_TIME = 0.5
const MAX_JUMP_TIME = 1.5

var ai_running_dir = Vector3()
var ai_time_dir_change = 0
var ai_jump_timer = rand_range(MIN_JUMP_TIME, MAX_JUMP_TIME)

var state = PAUSED

var movement = Vector3()

func random_dir():
	return Vector3(1, 0, 0).rotated(Vector3(0, 1, 0), rand_range(-PI, PI))

func fire():
	if fire_cooldown <= 0:
		var forward = Vector3(sin(rotation.y), 0, cos(rotation.y))
		var ball = preload("res://minigames/bowling/ball.tscn").instance()
		ball.rotation = rotation
		ball.translation = translation + 2*forward + Vector3(0, 0.25, 0)
		$"..".add_child(ball)
		
		fire_cooldown = FIRE_COOLDOWN_TIME

func _ready():
	$Model/AnimationPlayer.play("idle")

func _process(delta):
	fire_cooldown -= delta
	var dir = Vector3()
	if not is_ai and state != DEAD and state != PAUSED:
		if Input.is_action_pressed("player" + var2str(player_id) + "_up"):
			dir.z -= 1
		if Input.is_action_pressed("player" + var2str(player_id) + "_left"):
			dir.x -= 1
		if Input.is_action_pressed("player" + var2str(player_id) + "_down"):
			dir.z += 1
		if Input.is_action_pressed("player" + var2str(player_id) + "_right"):
			dir.x += 1
		
		if Input.is_action_pressed("player" + var2str(player_id) + "_action1") and is_on_floor():
			if state != JUMP:
				$Model/AnimationPlayer.play("jump")
				state = JUMP
			movement = Vector3(0, 4, 0)
		
		if Input.is_action_just_pressed("player" + var2str(player_id) + "_action2") and is_solo_player:
			fire()
	elif is_ai and state != DEAD and state != PAUSED:
		if not is_solo_player:
			ai_time_dir_change -= delta
			if ai_time_dir_change <= 0:
				ai_running_dir = random_dir()
				ai_time_dir_change = rand_range(MIN_DIR_CHANGE_TIME, MAX_DIR_CHANGE_TIME)
			
			var test_pos = translation + ai_running_dir * delta
			if not ground_box.has_point(Vector3(test_pos.x, 0, test_pos.z)):
				ai_running_dir = -ai_running_dir
			
			if is_on_floor():
				ai_jump_timer -= delta
				if ai_jump_timer <= 0:
					ai_jump_timer = rand_range(MIN_JUMP_TIME, MAX_JUMP_TIME)
					if state != JUMP:
						$Model/AnimationPlayer.play("jump")
						state = JUMP
					movement = Vector3(0, 4, 0)
			
			dir = ai_running_dir
		else:
			if fire_cooldown <= 0:
				var active_players = []
				for p in get_tree().get_nodes_in_group("players"):
					if p != self and p.state != DEAD:
						active_players.append(p)
				if not active_players.empty():
					var player = active_players[randi() % active_players.size()]
					var dir_to_player = player.translation - translation
					rotation.y = atan2(dir_to_player.x, dir_to_player.z) + rand_range(-PI/8, PI/8)
					fire()
			elif fire_cooldown < FIRE_COOLDOWN_TIME - 0.5:
				ai_time_dir_change -= delta
				if ai_time_dir_change <= 0:
					ai_running_dir = Vector3(1, 0, 0)
					if randi() % 2 == 0:
						ai_running_dir = -ai_running_dir
					ai_time_dir_change = rand_range(MIN_DIR_CHANGE_TIME, MAX_DIR_CHANGE_TIME)
				
				var test_pos = translation + ai_running_dir * delta
				if not solo_ground_box.has_point(Vector3(test_pos.x, 0, test_pos.z)):
					ai_running_dir = -ai_running_dir
				
				dir = ai_running_dir
	
	if translation.y < -2:
		if state != DEAD:
			state = DEAD
			$"..".knockout(self)
		queue_free()
	
	if dir.length() > 0:
		if state == IDLE:
			$Model/AnimationPlayer.play("run")
			state = RUNNING
		dir = dir.normalized()
		rotation = Vector3(0, atan2(dir.x, dir.z), 0)
	else:
		if state == RUNNING:
			$Model/AnimationPlayer.play("idle")
			state = IDLE
	
	movement += GRAVITY * delta
	
	if state != DEAD:
		move_and_slide(movement + dir * SPEED, Vector3(0, 1, 0))
		
		if is_on_floor():
			movement = Vector3()
			if state == JUMP:
				$Model/AnimationPlayer.play("idle")
				state = IDLE
	else:
		# Knock out all players that are hit by a knocked out player
		var collision = move_and_collide(movement * delta)
		
		if collision != null:
			if collision.collider.is_in_group("players"):
				collision.collider.knockout(movement)

func knockout(mov):
	if state != DEAD:
		state = DEAD
		$"..".knockout(self)
		movement = mov
