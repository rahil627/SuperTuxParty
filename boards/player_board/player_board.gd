extends Spatial

const MOVEMENT_SPEED = 5 # The speed used for walking to destination
const MIN_MOVEMENT_SPEED = 2

# The position this node is walking to, used for animation
var destination = []

var player_id = 0
var player_name = "" # Name that player has chosen
var space = 1 # Space on the board the player is on
var cookies = 0
var cakes = 0

func _ready():
	player_name = name
	add_to_group("players")

func _physics_process(delta):
	if(destination.size() > 0):
		var direction = (destination[0] - translation)
		translation +=  (MOVEMENT_SPEED * direction.length()) * direction.normalized() * delta;
		
		if (destination.size() > 1):
			if(direction.length() < 0.3):
				destination.pop_front()
		elif(direction.length() < 0.01):
			destination.pop_front()