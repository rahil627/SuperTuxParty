extends Spatial

const LAVA_RISE_SPEED = 0.25

var num_players_alive = 4

onready var stages = [$Stage1, $Stage2, $Stage3]
var current_stage = -1
var has_chosen = false

func _ready():
	enter_stage($Player1, 0)

func process_stage(stage):
	var index = (randi() % stage.get_child_count())
	stage.get_child(index).can_be_opened = false

func open_door(index):
	if current_stage < stages.size() and not has_chosen:
		stages[current_stage].get_child(index).can_be_opened = false
		has_chosen = true
		
		$Screen/ControlView2D.clear_display();
		$Screen/ControlView2D2.clear_display();
		$Screen/ControlView2D3.clear_display();

func enter_stage(body, new_stage):
	if not body.is_in_group("players"):
		return
	
	if new_stage > current_stage:
		current_stage = new_stage
		has_chosen = false
		
		if current_stage < stages.size():
			$Player4.process_next_stage()
			
			$Screen/ControlView2D.display_action("player%d_action1" % $Player4.player_id)
			$Screen/ControlView2D2.display_action("player%d_action2" % $Player4.player_id)
			$Screen/ControlView2D3.display_action("player%d_action3" % $Player4.player_id)

func _process(delta):
	var min_progress = null
	
	for player in get_tree().get_nodes_in_group("players"):
		if not player.is_dead() and (min_progress == null or player.translation.z < min_progress.z):
			min_progress = player.translation
	
	if min_progress != null:
		$Camera.translation +=  (Vector3(0, min_progress.y, min_progress.z) + Vector3(0, 3, -4) - $Camera.translation) * delta
	
	$Lava.translation += Vector3(0, 1, 0) * delta * LAVA_RISE_SPEED


func _on_Lava_body_entered(body):
	if body.is_in_group("players"):
		if not body.is_dead():
			body.die()
			num_players_alive -= 1
			
			if num_players_alive == 1:
				end_game()
	elif body.is_in_group("door"):
		body.destroy()


func _on_Finish_body_entered(body):
	if body.is_in_group("players"):
		body.has_finished = true
		body.die()
		
		end_game()

func end_game():
	$Screen/Label.show()
	$EndTimer.start()
	
	for player in get_tree().get_nodes_in_group("players"):
		if not player.is_dead():
			player.die()

func _on_EndTimer_timeout():
	if num_players_alive > 1:
		Global.goto_board(0)
	else:
		Global.goto_board(1)
