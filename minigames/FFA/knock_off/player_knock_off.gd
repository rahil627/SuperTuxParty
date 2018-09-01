extends RigidBody

const ICE_RADIUS = 3
const MAX_SPEED = 4
const PLAYER_RADIUS = 0.5

var player_id = 0
var accel = 15
var is_ai = false

func _ready():
	$Model.set_as_toplevel(true)
	add_to_group("players")

func _process(delta):
	var dir = Vector3()
	
	$Model.translation = self.translation + Vector3(0, 0.5, 0)
	
	var players = get_tree().get_nodes_in_group("players")
	
	if not is_ai:
		if Input.is_action_pressed("player" + var2str(player_id) + "_up"):
			dir.x -= accel * delta
		if Input.is_action_pressed("player" + var2str(player_id) + "_down"):
			dir.x += accel * delta
		if Input.is_action_pressed("player" + var2str(player_id) + "_left"):
			dir.z += accel * delta
		if Input.is_action_pressed("player" + var2str(player_id) + "_right"):
			dir.z -= accel * delta
	else:
		# Try to knock off the player, that is the farthest away from the center, yet still on the ice
		var farthest_player
		for p in players:
			if p != self and p.translation.length() - PLAYER_RADIUS < ICE_RADIUS and (farthest_player == null or (farthest_player.translation - translation).length_squared() > (p.translation - translation).length_squared()):
				farthest_player = p
		
		if farthest_player != null:
			dir = (farthest_player.translation - translation).rotated(Vector3(0, 1, 0), PI/2)
		else:
			# Everybody knocked off the board?
			# Move towards the center
			dir = self.translation.rotated(Vector3(0, 1, 0), -PI/2)
	
	dir = dir.normalized()
	
	angular_velocity += dir * accel * delta
	
	if angular_velocity.length() > MAX_SPEED:
		angular_velocity = MAX_SPEED * angular_velocity.normalized()
