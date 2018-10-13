extends KinematicBody

const MOVEMENT_SPEED = 2

var is_ai
var player_id

var plants = 0

var movement = Vector3()

var is_walking = false

var input_disabled

onready var plant_spots = [$"../Area1", $"../Area2", $"../Area3", $"../Area4"]

var current_destination = null

func _ready():
	$Model/AnimationPlayer.play("idle")

func has_player(colliders, blacklist):
	for collider in colliders:
		if not blacklist.has(collider) and collider.is_in_group("players"):
			return true
	
	return false

func _physics_process(delta):
	var dir = Vector3()
	
	if not is_ai:
		if Input.is_action_pressed("player" + var2str(player_id) + "_up"):
			dir.x += 1
		if Input.is_action_pressed("player" + var2str(player_id) + "_down"):
			dir.x -= 1
		if Input.is_action_pressed("player" + var2str(player_id) + "_left"):
			dir.z -= 1
		if Input.is_action_pressed("player" + var2str(player_id) + "_right"):
			dir.z += 1
	else:
		if current_destination == null or has_player(current_destination.get_overlapping_bodies(), [self]):
			var spots = []
			
			for plant in plant_spots:
				var colliders = plant.get_overlapping_bodies()
				# Dont blacklist self beause the colliders might not have been updated yet.
				# If everything is occupied, the AI will wait a turn
				if not has_player(colliders, []):
					spots.append(plant)
			
			if not spots.empty():
				current_destination = spots[randi() % spots.size()]
		
		var destination_vec = current_destination.translation - self.translation
		
		if destination_vec.length_squared() > 0.01:
			dir = destination_vec.normalized()
	
	movement += Vector3(0, -9.81, 0) * delta
	if input_disabled:
		move_and_slide(movement, Vector3(0, 1, 0))
	else:
		move_and_slide(movement + dir * MOVEMENT_SPEED, Vector3(0, 1, 0))
	
	if dir.length_squared() > 0 and not input_disabled:
		rotation.y = atan2(dir.x, dir.z)
	
	if (dir.length_squared() > 0 and not input_disabled) and not is_walking:
		$Model/AnimationPlayer.play("run")
		is_walking = true
	elif (dir.length_squared() == 0 or input_disabled) and is_walking:
		$Model/AnimationPlayer.play("idle")
		is_walking = false
	
	if is_on_floor():
		movement = Vector3()

func play_animation(name):
	$Model/AnimationPlayer.play(name)