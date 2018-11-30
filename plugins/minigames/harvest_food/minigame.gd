extends Spatial

const ROTTEN_PLANT = "res://plugins/minigames/harvest_food/plants/carrot_rotten.tscn"
const NORMAL_PLANT = "res://plugins/minigames/harvest_food/plants/carrot.tscn"

var rounds = 5

var plants
var rotten_index

func _ready():
	$Screen/Player1Name.text = Global.players[$Player1.player_id - 1].player_name
	$Screen/Player2Name.text = Global.players[$Player2.player_id - 1].player_name
	if Global.minigame_type != Global.DUEL:
		$Screen/Player3Name.text = Global.players[$Player3.player_id - 1].player_name
		$Screen/Player4Name.text = Global.players[$Player4.player_id - 1].player_name
		
		plants = [$Area1, $Area2, $Area3, $Area4]
	else:
		plants = [$Area2, $Area4]
		rounds = 3
		
		$Area1.queue_free()
		$Area3.queue_free()
		
		$Screen/Player3Name.queue_free()
		$Screen/Player3.queue_free()
		$Screen/Player4Name.queue_free()
		$Screen/Player4.queue_free()
	spawn_plants()

func spawn_plants():
	rotten_index = randi() % plants.size()
	
	for i in range(plants.size()):
		var plant
		if i == rotten_index:
			plant = preload(ROTTEN_PLANT).instance()
		else:
			plant = preload(NORMAL_PLANT).instance()
		
		plants[i].add_child(plant)
	
	$Timer.start()

func _on_Timer_timeout():
	# Move every player in front of the spot
	$Player1.input_disabled = true
	$Player1.current_destination = $Player1.translation - $Player1.translation.normalized()
	$Player2.input_disabled = true
	$Player2.current_destination = $Player2.translation - $Player2.translation.normalized()
	if Global.minigame_type != Global.DUEL:
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
					$Screen/Message.text = "%s has chosen the rotten plant!" % Global.players[collider.player_id - 1].player_name
		
		var animationplayer = plants[i].get_node("Carrot/AnimationPlayer")
		animationplayer.play("show")
	
	rounds -= 1
	update_overlay()
	
	# Wait 5 seconds
	yield(get_tree().create_timer(5.0), "timeout")
	
	$Player1.input_disabled = false
	$Player1.play_animation("idle")
	$Player1.translation = Vector3(-1, 0.44, -1)
	$Player1.current_destination = null
	$Player2.input_disabled = false
	$Player2.play_animation("idle")
	$Player2.translation = Vector3(1, 0.44, -1)
	$Player2.current_destination = null
	if Global.minigame_type != Global.DUEL:
		$Player3.input_disabled = false
		$Player3.play_animation("idle")
		$Player3.translation = Vector3(1, 0.44, 1)
		$Player3.current_destination = null
		$Player4.input_disabled = false
		$Player4.play_animation("idle")
		$Player4.translation = Vector3(-1, 0.44, 1)
		$Player4.current_destination = null
	
	$Screen/Message.text = ""
	
	for plant in plants:
		var model = plant.get_node("Carrot")
		
		plant.remove_child(model)
		model.queue_free()
	
	if rounds > 0:
		spawn_plants()
	else:
		var placement
		match Global.minigame_type:
			Global.FREE_FOR_ALL, Global.DUEL:
				var players
				if Global.minigame_type == Global.DUEL:
					placement = [1, 2]
					players = [$Player1, $Player2]
				else:
					placement = [1, 2, 3, 4]
					players = [$Player1, $Player2, $Player3, $Player4]
				
				placement.sort_custom(Sorter.new(players), "_sort")
				for i in range(placement.size()):
					placement[i] = players[placement[i] - 1].player_id
			Global.TWO_VS_TWO:
				if $Player1.plants + $Player2.plants >= $Player3.plants + $Player4.plants:
					placement = 0
				else:
					placement = 1
		
		Global.goto_board(placement)

func update_overlay():
	$Screen/Player1.text = var2str($Player1.plants)
	$Screen/Player2.text = var2str($Player2.plants)
	if Global.minigame_type != Global.DUEL:
		$Screen/Player3.text = var2str($Player3.plants)
		$Screen/Player4.text = var2str($Player4.plants)

func _process(delta):
	$Screen/Time.text = var2str(stepify($Timer.time_left, 0.01))

class Sorter:
	var players
	
	func _init(players):
		self.players = players
	
	func _sort(a, b):
		return players[a - 1].plants > players[b - 1].plants
