extends Spatial

const MOVEMENT_SPEED = 7 # The speed used for walking to destination
const GUI_TIMER = 0.2

const MAX_ITEMS = 3

class WalkingState:
	var space: NodeBoard
	var position: Vector3

# The position this node is walking to, used for animation
var destination := []

signal walking_step
signal walking_ended

var player_id := 0
var player_name := "" # Name that player has chosen
var is_ai := false
var ai_difficulty: int = Global.Difficulty.NORMAL
var space: Spatial # Space on the board the player is on
var cookies := 0
var cakes := 0
var cookies_gui := 0
var gui_timer: float = GUI_TIMER
var target_rotation := 0.0

onready var controller := get_tree().get_nodes_in_group("Controller")[0]\
		as Spatial

var is_walking := false

var items := [preload("res://plugins/items/dice/item.gd").new()]
var roll_modifiers := []

func give_item(item: Item) -> bool:
	if items.size() < MAX_ITEMS:
		items.push_back(item)
		controller.update_player_info()
		return true

	return false

func remove_item(item: Item) -> bool:
	var index: int = items.find(item)
	if index >= 0:
		items.remove(index)
		controller.update_player_info()
		return true

	return false

func add_roll_modifier(amount: int, num_rounds: int):
	roll_modifiers.push_back([amount, num_rounds])

func get_total_roll_modifier():
	var res := 0
	for mod in roll_modifiers:
		res += mod[0]

	return res

func roll_modifiers_count_down():
	var newarr = []
	for mod in roll_modifiers:
		mod[1] -= 1
		if mod[1] > 0:
			newarr.push_back(mod)
	
	roll_modifiers = newarr

func walk_to(new_space: Spatial) -> void:
	var old_space: NodeBoard = space
	space = new_space
	controller.update_space(old_space)
	controller.update_space(new_space)

func teleport_to(new_space: Spatial) -> void:
	var old_space: NodeBoard = space
	space = new_space
	controller.update_space(old_space)
	controller.update_space(new_space)
	translation = destination.back().position
	destination.clear()

func _physics_process(delta: float) -> void:
	if destination.size() > 0:
		if not is_walking:
			$Model.play_animation("walk")
			is_walking = true

		var dir: Vector3 = destination[0].position - translation
		var movement: Vector3 = MOVEMENT_SPEED * dir.normalized() * delta
		translation += movement

		target_rotation = atan2(dir.normalized().x, dir.normalized().z)

		if dir.length() < 2 * delta * MOVEMENT_SPEED:
			var state = destination.pop_front()
			emit_signal("walking_step", state.space)

		if destination.size() == 0:
			target_rotation = 0

			$Model.play_animation("idle")
			is_walking = false

			controller.update_player_info()
			emit_signal("walking_ended")
	else:
		target_rotation = 0
		if cookies_gui < cookies:
			gui_timer -= delta

			if gui_timer <= 0:
				gui_timer = GUI_TIMER
				cookies_gui += 1
				controller.update_player_info()
		elif cookies_gui > cookies:
			gui_timer -= delta

			if gui_timer <= 0:
				gui_timer = GUI_TIMER
				cookies_gui -= 1
				controller.update_player_info()

	var dist: float = rotation.y - target_rotation

	if abs(dist) > deg2rad(0.1):
		while dist > PI:
			dist -= TAU
		while dist < -PI:
			dist += TAU

		if dist > 0:
			rotation.y -= 5 * delta * dist
		else:
			rotation.y += 5 * delta * abs(dist)
