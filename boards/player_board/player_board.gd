extends Spatial

const MOVEMENT_SPEED = 5 # The speed used for walking to destination
const GUI_TIMER = 0.2

# The position this node is walking to, used for animation
var destination = []

var player_id = 0
var player_name = "" # Name that player has chosen
var is_ai = false
var space = null # Space on the board the player is on
var cookies = 0
var cakes = 0
var cookies_gui = 0
var gui_timer = GUI_TIMER

var is_walking = false

func _init():
	add_to_group("players")

func _ready():
	if has_node("Model/AnimationPlayer"):
		$Model/AnimationPlayer.play("idle")

func _physics_process(delta):
	if destination.size() > 0:
		if not is_walking and has_node("Model/AnimationPlayer"):
			$Model/AnimationPlayer.play("walk")
			is_walking = true
		
		var dir = (destination[0] - translation)
		translation +=  (MOVEMENT_SPEED * dir.length()) * dir.normalized() * delta;
		
		rotation.y = atan2(dir.normalized().x, dir.normalized().z)
		
		if destination.size() > 1:
			if dir.length() < 0.3:
				destination.pop_front()
				$"../Controller".animation_step(player_id)
		elif dir.length() < 0.01:
			destination.pop_front()
			$"../Controller".animation_step(player_id)
		
		if destination.size() == 0:
			rotation.y = 0
			if has_node("Model/AnimationPlayer"):
				$Model/AnimationPlayer.play("idle")
				is_walking = false
			$"../Controller".update_player_info()
			$"../Controller".animation_ended(player_id)
	else:
		if cookies_gui < cookies:
			gui_timer -= delta
			
			if gui_timer <= 0:
				gui_timer = GUI_TIMER
				cookies_gui += 1
				$"../Controller".update_player_info()
		elif cookies_gui > cookies:
			gui_timer -= delta
			
			if gui_timer <= 0:
				gui_timer = GUI_TIMER
				cookies_gui -= 1
				$"../Controller".update_player_info()