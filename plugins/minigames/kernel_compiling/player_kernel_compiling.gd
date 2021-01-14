extends Spatial

const NEEDED_BUTTON_PRESSES := 50
var AI_MIN_WAIT_TIME: float
var AI_MAX_WAIT_TIME: float

const ACTIONS := ["up", "down", "left", "right", "action1", "action2", "action3", "action4"]

var presses := 0

var player_id: int

var is_ai: bool
var ai_difficulty: int
var ai_wait_time: float

var next_action: String

var disabled_input = false

var teammate: Node

func get_percentage():
	return float(presses) / NEEDED_BUTTON_PRESSES

func disable_input():
	$Wrong.play()
	disabled_input = true
	$PenaltyTimer.start()

func generate_next_action():
	if get_parent().game_ended:
		return
	var action = "player" + str(player_id) + "_" + ACTIONS[randi() % ACTIONS.size()]
	next_action = action
	$Screen/ControlView.display_action(action)

func clear_action():
	next_action = ""
	$Screen/ControlView.clear_display()

func update_progress():
	if Global.minigame_state.minigame_type != Global.MINIGAME_TYPES.TWO_VS_TWO:
		$Progress/Sprite3D.material_override.set_shader_param("percentage", get_percentage())
	else:
		get_parent().update_progress()

func _ready():
	$Model.jump_to_animation("sit")
	
	if Global.minigame_state.minigame_type == Global.MINIGAME_TYPES.TWO_VS_TWO:
		$Screen.translation.y -= 0.15
		$Progress.hide()
	
	if is_ai:
		match ai_difficulty:
			Global.Difficulty.EASY:
				AI_MIN_WAIT_TIME = 0.8
				AI_MAX_WAIT_TIME = 1.0
			Global.Difficulty.HARD:
				AI_MIN_WAIT_TIME = 0.4
				AI_MAX_WAIT_TIME = 0.6
			_:
				AI_MIN_WAIT_TIME = 0.6
				AI_MAX_WAIT_TIME = 0.8
		
		ai_wait_time = rand_range(AI_MIN_WAIT_TIME, AI_MAX_WAIT_TIME)

func press():
	presses += 1
	if teammate:
		teammate.presses += 1
	$Correct.play()
	clear_action()
	update_progress()
	if presses < NEEDED_BUTTON_PRESSES:
		get_tree().create_timer(0.25).connect("timeout", self, "generate_next_action")
	else:
		get_parent().stop_game()

func _process(delta):
	if is_ai and next_action and not disabled_input:
		ai_wait_time -= delta
		if ai_wait_time <= 0:
			press()
			ai_wait_time = rand_range(AI_MIN_WAIT_TIME, AI_MAX_WAIT_TIME)

func _input(event):
	if next_action and not disabled_input and not is_ai:
		if event.is_action_pressed(next_action):
			press()
		else:
			# Check if it was another action by that player
			for action in ACTIONS:
				if event.is_action_pressed("player" + str(player_id) + "_" + action):
					disable_input()
					$Screen/ControlView.hide()
					$Screen/PenaltySplash.show()
					return

func _on_PenaltyTimer_timeout():
	disabled_input = false
	$Screen/PenaltySplash.hide()
	$Screen/ControlView.show()
