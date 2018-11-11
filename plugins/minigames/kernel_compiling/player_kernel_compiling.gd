extends Spatial

const NEEDED_BUTTON_PRESSES = 10
const AI_MIN_WAIT_TIME = 0.5
const AI_MAX_WAIT_TIME = 1

const ACTIONS = ["up", "down", "left", "right", "action1", "action2", "action3", "action4"]

var presses = 0

var player_id

var is_ai
var ai_wait_time

var next_action

var idx
var disabled_input = false

func disable_input():
	$Model/AnimationPlayer.play("sad")
	disabled_input = true
	$PenalityTimer.start()

func _ready():
	$Model/AnimationPlayer.play("idle")
	
	if is_ai:
		ai_wait_time = rand_range(AI_MIN_WAIT_TIME, AI_MAX_WAIT_TIME)

func press():
	$Model/AnimationPlayer.play("punch")
	$Model/AnimationPlayer.queue("idle")
	presses += 1
	$Battery/Cylinder.get_surface_material(0).set_shader_param("percentage", float(presses) / NEEDED_BUTTON_PRESSES)
	if presses < NEEDED_BUTTON_PRESSES:
		$"..".next_action(idx)
	else:
		$"..".stop_game()

func _process(delta):
	if is_ai and next_action != null and not disabled_input:
		ai_wait_time -= delta
		if ai_wait_time <= 0:
			if randi() % 4 != 0:
				press()
			else:
				disable_input()
			ai_wait_time = rand_range(AI_MIN_WAIT_TIME, AI_MAX_WAIT_TIME)

func _input(event):
	if next_action != null and not disabled_input and not is_ai:
		if event.is_action_pressed(next_action):
			press()
		else:
			# Check if it was another action by that player
			for action in ACTIONS:
				if event.is_action_pressed("player"+var2str(player_id)+"_"+action):
					disable_input()
					return

func _on_PenalityTimer_timeout():
	disabled_input = false
	$Model/AnimationPlayer.play("idle")
