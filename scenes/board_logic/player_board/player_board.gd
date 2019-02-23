extends Spatial

const MOVEMENT_SPEED = 7 # The speed used for walking to destination
const GUI_TIMER = 0.2

const MAX_ITEMS = 3

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
var target_rotation = 0

onready var controller = get_tree().get_nodes_in_group("Controller")[0]

var is_walking = false

var items = [ preload("res://plugins/items/dice/item.gd").new() ]

func _ready():
	if has_node("Model/AnimationPlayer"):
		$Model/AnimationPlayer.play("idle")

func give_item(item):
	if items.size() < MAX_ITEMS:
		items.push_back(item)
		controller.update_player_info()
		return true
	
	return false

func remove_item(item):
	var index = items.find(item)
	if index >= 0:
		items.remove(index)
		controller.update_player_info()
		return true
	
	return false

func _physics_process(delta):
	if destination.size() > 0:
		if not is_walking and has_node("Model/AnimationPlayer"):
			$Model/AnimationPlayer.play("walk")
			is_walking = true
		
		var dir = (destination[0] - translation)
		var movement = MOVEMENT_SPEED * dir.normalized() * delta
		if movement.length_squared() <= dir.length_squared():
			translation += movement
		else:
			translation += dir
		
		target_rotation = atan2(dir.normalized().x, dir.normalized().z)
		
		if dir.length() < 0.01:
			destination.pop_front()
			$"../Controller".animation_step(player_id)
		
		if destination.size() == 0:
			target_rotation = 0
			
			if has_node("Model/AnimationPlayer"):
				$Model/AnimationPlayer.play("idle")
				is_walking = false
			
			$"../Controller".update_player_info()
			$"../Controller".animation_ended(player_id)
	else:
		target_rotation = 0
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
	
	var dist = rotation.y - target_rotation
	
	if abs(dist) > deg2rad(0.1):
		while dist > PI:
			dist -= TAU
		while dist < -PI:
			dist += TAU
		
		if dist > 0:
			rotation.y -= 5 * delta * dist
		else:
			rotation.y += 5 * delta * abs(dist)