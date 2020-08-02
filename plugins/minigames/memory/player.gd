extends Spatial

const TEAM_COLORS = [Color.lightblue, Color.lightcoral]

var player_id: int
var is_ai: bool
var ai_difficulty: int

export var row := 1
export var column := 1
onready var right_side := column > 4

export var ally: NodePath

var blocked := false
var points := 0 setget set_points

var ai_target_row := -1
var ai_target_column := -1

var cooldown := 0.0
onready var team := 0 if player_id in Global.minigame_state.minigame_teams[0] else 1

func set_points(num: int):
	points = num

	get_parent().get_node("ScoreOverlay").set_score(player_id, num)

func card_at(row: int, column: int) -> Node:
	if row < 0 or column < 0:
		return null

	return get_parent().get_node("Row{0}/{1}".format([row, column]))

func current_card():
	return card_at(row, column)

func random_card(variant: int) -> Array:
	var rand_value
	match ai_difficulty:
		Global.Difficulty.EASY:
			rand_value = 6
		Global.Difficulty.NORMAL:
			rand_value = 4
		Global.Difficulty.HARD:
			rand_value = 1
	# Make the AI fail some times (probability depends on the difficulty)
	if randi() % rand_value != 0:
		variant = -1
	var places = []
	var beginning := 1
	var end := 8
	if right_side:
		beginning = 5
	else:
		end = 4
	for row in range(1, 5):
		for column in range(beginning, end):
			var card = card_at(row, column)
			if not card.faceup and (variant < 0 or card.variant == variant):
				places.push_back([row, column])
	if not places:
		return [-1, -1]
	return places[randi() % len(places)]

func _ready():
	current_card().show_player(player_id)

func activate():
	if current_card().faceup:
		return

	$Flip.play()
	blocked = true
	var ally_node = get_node(ally)
	# Make the other player choose a new card (when it's an AI)
	ally_node.ai_target_row = -1
	ally_node.ai_target_column = -1
	yield(current_card().flip_up(TEAM_COLORS[self.team]), "animation_finished")
	yield(get_tree().create_timer(0.25), "timeout")

	if ally_node.blocked:
		var ally_card = ally_node.current_card()
		if ally_card.is_animation_running():
			yield(ally_card.animation_player(), "animation_finished")
		if ally_card.variant == current_card().variant:
			$Point.play()
			self.points += 1
		else:
			# wait for the animation to complete
			ally_node.cooldown = 0.5
			cooldown = 0.5
			ally_card.flip_down()
			current_card().flip_down()
		blocked = false
		ally_node.blocked = false

func _process(delta):
	cooldown = max(0, cooldown - delta)
	if blocked:
		return

	if is_ai and not cooldown:
		current_card().hide_player(player_id)
		var card = card_at(ai_target_row, ai_target_column)
		var ally_node = get_node(ally)
		var variant = -1
		var ally_card = null
		if ally_node.blocked:
			ally_card = ally_node.current_card()
			variant = ally_card.variant
		if not card or card.faceup:
			var random_pos = random_card(variant)
			ai_target_row = random_pos[0]
			ai_target_column = random_pos[1]
		if ai_target_row >= 0 and ai_target_row < row:
			row -= 1
		elif ai_target_row >= 0 and ai_target_row > row:
			row += 1
		elif ai_target_column >= 0 and ai_target_column < column:
			column -= 1
		elif ai_target_column >= 0 and ai_target_column > column:
			column += 1
		else:
			current_card().show_player(player_id)
			# FIXME: GDScript has no await-keyword yet
			# Will likely be added for 4.0, refactor this then
			var result = activate()
			while result is GDScriptFunctionState:
				result = yield(result,"completed")
		current_card().show_player(player_id)
		cooldown = 0.25

func _input(event: InputEvent):
	if blocked or cooldown:
		return

	current_card().hide_player(player_id)

	var beginning := 1
	var end := 7
	if right_side:
		beginning = 5
	else:
		end = 3

	if not is_ai:
		if event.is_action_pressed("player{0}_left".format([player_id])) and column > beginning:
			column -= 1
			cooldown = 0.1
		if event.is_action_pressed("player{0}_right".format([player_id])) and column < end:
			column += 1
			cooldown = 0.1
		if event.is_action_pressed("player{0}_up".format([player_id])) and row > 1:
			row -= 1
			cooldown = 0.1
		if event.is_action_pressed("player{0}_down".format([player_id])) and row < 4:
			row += 1
			cooldown = 0.1
		if event.is_action_pressed("player{0}_action1".format([player_id])):
			current_card().show_player(player_id)
			# FIXME: GDScript has no await-keyword yet
			# Will likely be added for 4.0, refactor this then
			var result = activate()
			while result is GDScriptFunctionState:
				result = yield(result,"completed")
			cooldown = 0.1

	current_card().show_player(player_id)
