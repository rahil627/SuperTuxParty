extends KinematicBody

const GRAVITY = 15 # Acceleration of gravity
const GRAVITY_DIR = Vector3(0, -1, 0) # Direction of gravity
const JUMP_MAX = 10
const JUMP_VECTOR = Vector3(0, 5, 0)
const ACCELERATION_DIR = Vector3(0, 0, 1)

var player_id = 1
var jump = JUMP_MAX
var movement = Vector3()
var is_ai = false
var stop = false

var playing_jump_animation = false
var walking_animation_position = 0

var next_jump_randomness = 0

var acceleration = 0
var disable_jump = 0 # Disables the player to jump for x seconds
var disable_jump_immunity = 0 # While this is on, the player will no longer be penalized when hitting a hurdle

var collision_disabled = 0

var visibility_material;

func _ready():
	if has_node("Model/AnimationPlayer"):
		get_node("Model/AnimationPlayer").play("run")
	
	visibility_material = load("res://plugins/minigames/hurdle/visibility.tres").duplicate()
	
	Utility.apply_nextpass_material(visibility_material, $Model)

func _physics_process(delta):
	if disable_jump == 0 and jump > 0 and stop == false:
		if not is_ai and Input.is_action_pressed("player" + var2str(player_id) + "_action1") :
			movement = JUMP_VECTOR
		elif is_ai and collision_disabled <= 0:
			for hurdle in get_tree().get_nodes_in_group("hurdles"):
				var dir = hurdle.translation - self.translation
				if dir.length() < 2.5 + next_jump_randomness and dir.angle_to(Vector3(0, 0, 1)) < PI/2 and abs(dir.x) < 0.5:
					movement = JUMP_VECTOR
					next_jump_randomness = randf() - 0.5
	if stop:
		acceleration = -6
	
	
	move_and_slide(acceleration * ACCELERATION_DIR, Vector3(0.0, 1.0, 0.0))
	acceleration = max(0, acceleration - delta)
	if translation.z > 6:
		translation.z = 6
	
	movement += GRAVITY * GRAVITY_DIR * delta
	
	if jump < JUMP_MAX and not playing_jump_animation and has_node("Model/AnimationPlayer"):
		walking_animation_position = $Model/AnimationPlayer.current_animation_position
		$Model/AnimationPlayer.play("jump")
		playing_jump_animation = true
	
	move_and_slide(movement, Vector3(0.0, 1.0, 0.0))
	jump -= 1
	
	disable_jump = max(0, disable_jump - delta)
	disable_jump_immunity = max(0, disable_jump_immunity - delta)
	collision_disabled -= delta
	if collision_disabled <= 0:
		set_collision_mask_bit(1, true)
	
	visibility_material.set_shader_param("time_invisible", collision_disabled)
	
	for i in range(get_slide_count()):
		var collision = get_slide_collision(i)
		
		# Check if it we hit a hurdle and if we did not land on top of it
		# Makes the player unable to move for a short duration
		# This prevents some weird jumps, like you just hit the hurdle and you saved yourself through jumping mid air
		if disable_jump_immunity == 0 and collision.collider.is_in_group("hurdles") and collision.normal.angle_to(Vector3(0, 1, 0)) > deg2rad(20):
			disable_jump = 0.25
			disable_jump_immunity = 1.0
			if has_node("Model/AnimationPlayer"):
				$Model/AnimationPlayer.stop()
	
	if is_on_floor():
		if playing_jump_animation and has_node("Model/AnimationPlayer"):
			$Model/AnimationPlayer.play("run")
			$Model/AnimationPlayer.seek(walking_animation_position)
			playing_jump_animation = false
		movement = Vector3()
		jump = JUMP_MAX

func disable_collision(duration):
	collision_disabled = duration
	set_collision_mask_bit(1, false)