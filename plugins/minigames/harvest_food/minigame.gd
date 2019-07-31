extends Spatial

const ROTTEN_PLANTS = [
						preload("res://plugins/minigames/harvest_food/plants/carrot_rotten.tscn"),
						preload("res://plugins/minigames/harvest_food/plants/radish_rotten.tscn"),
						preload("res://plugins/minigames/harvest_food/plants/potato_rotten.tscn")
					  ]
const NORMAL_PLANTS = [
						preload("res://plugins/minigames/harvest_food/plants/carrot.tscn"), preload("res://plugins/minigames/harvest_food/plants/carrot.tscn"),
						preload("res://plugins/minigames/harvest_food/plants/carrot.tscn"), preload("res://plugins/minigames/harvest_food/plants/radish.tscn"),
						preload("res://plugins/minigames/harvest_food/plants/carrot.tscn"), preload("res://plugins/minigames/harvest_food/plants/potato.tscn")
					  ]

var rounds = 5

var plants
var rotten_index

func _ready():
	if Global.minigame_type != Global.MINIGAME_TYPES.DUEL:
		plants = [$Area1, $Area2, $Area3, $Area4]
	else:
		plants = [$Area2, $Area4]
		rounds = 3
		
		$Area1.queue_free()
		$Area3.queue_free()
	spawn_plants()

func spawn_plants():
	rotten_index = randi() % plants.size()
	
	for i in range(plants.size()):
		var plant
		if i == rotten_index:
			plant = ROTTEN_PLANTS[randi() % ROTTEN_PLANTS.size()].instance()
		else:
			plant = NORMAL_PLANTS[randi() % NORMAL_PLANTS.size()].instance()
		
		plants[i].add_child(plant)
	
	$Timer.start()

func _on_Timer_timeout():
	# Move every player in front of the spot
	$Player1.input_disabled = true
	$Player1.current_destination = $Player1.translation - $Player1.translation.normalized()
	$Player2.input_disabled = true
	$Player2.current_destination = $Player2.translation - $Player2.translation.normalized()
	if Global.minigame_type != Global.MINIGAME_TYPES.DUEL:
		$Player3.input_disabled = true
		$Player3.current_destination = $Player3.translation - $Player3.translation.normalized()
		$Player3.rotation = Vector3(0, -PI/2, 0)
		$Player4.input_disabled = true
		$Player4.current_destination = $Player4.translation - $Player4.translation.normalized()
		$Player4.rotation = Vector3(0, -PI/2, 0)
	
	for i in range(plants.size()):
		var colliders = plants[i].get_overlapping_bodies()
		
		if i != rotten_index:
			for collider in colliders:
				if collider.is_in_group("players"):
					collider.plants += 1
					collider.play_animation("happy")
		else:
			for collider in colliders:
				if collider.is_in_group("players"):
					collider.play_animation("sad")
					$Screen/Message.text = tr("HARVEST_FOOD_SELECT_ROTTEN_PLANT_MSG") % Global.players[collider.player_id - 1].player_name
		
		var animationplayer = plants[i].get_node("Plant/AnimationPlayer")
		animationplayer.play("show")
	
	rounds -= 1
	update_overlay()
	
	# Wait 5 seconds
	yield(get_tree().create_timer(5.0), "timeout")
	
	$Player1.input_disabled = false
	$Player1.play_animation("idle")
	$Player1.translation = Vector3(-1, 0, -1)
	$Player1.current_destination = null
	$Player2.input_disabled = false
	$Player2.play_animation("idle")
	$Player2.translation = Vector3(1, 0, -1)
	$Player2.current_destination = null
	if Global.minigame_type != Global.MINIGAME_TYPES.DUEL:
		$Player3.input_disabled = false
		$Player3.play_animation("idle")
		$Player3.translation = Vector3(1, 0, 1)
		$Player3.current_destination = null
		$Player4.input_disabled = false
		$Player4.play_animation("idle")
		$Player4.translation = Vector3(-1, 0, 1)
		$Player4.current_destination = null
	
	$Screen/Message.text = ""
	
	for plant in plants:
		var model = plant.get_node("Plant")
		
		plant.remove_child(model)
		model.queue_free()
	
	if rounds > 0:
		spawn_plants()
	else:
		match Global.minigame_type:
			Global.MINIGAME_TYPES.FREE_FOR_ALL:
				Global.minigame_win_by_points([$Player1.plants, $Player2.plants, $Player3.plants, $Player4.plants])
			Global.MINIGAME_TYPES.DUEL:
				Global.minigame_win_by_points([$Player1.plants, $Player2.plants])
			Global.MINIGAME_TYPES.TWO_VS_TWO:
				Global.minigame_team_win_by_points([$Player1.plants + $Player2.plants, $Player3.plants + $Player4.plants])

func update_overlay():
	$Screen/ScoreOverlay.set_score(1, $Player1.plants)
	$Screen/ScoreOverlay.set_score(2, $Player2.plants)
	if Global.minigame_type != Global.MINIGAME_TYPES.DUEL:
		$Screen/ScoreOverlay.set_score(3, $Player3.plants)
		$Screen/ScoreOverlay.set_score(4, $Player4.plants)

func _process(_delta):
	$Screen/Time.text = var2str(stepify($Timer.time_left, 0.01))
