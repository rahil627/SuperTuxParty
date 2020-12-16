extends Spatial

const HURDLES = [
	preload("res://plugins/minigames/hurdle/hurdles/normal_hurdle/hurdle.tscn"),
	preload("res://plugins/minigames/hurdle/hurdles/trashcan/trashcan.tscn")
]

const POWERUPS = [
	preload("res://plugins/minigames/hurdle/powerups/star/star.tscn"),
	preload("res://plugins/minigames/hurdle/powerups/landmine/landmine.tscn"),
	preload("res://plugins/minigames/hurdle/powerups/ghost_powerup/ghost_powerup.tscn")
]

var losses = 0 # Number of players that have been knocked-out
var placement = [0, 0, 0, 0] # Placements, is filled with player id in order. Index 0 is first place
var timer = 50.0 # Timer of minigame
var end_timer = 5.0 # How long the winning message will be shown before exiting
var end_timer_start = false # When to start the end timer
var spawn_timer = 5
var max_spawn = 3

var powerup_spawn_timer = 3
var powerup_max_spawn = 3

onready var hurdle1_pointer = $Hurdle1
onready var hurdle2_pointer = $Hurdle2
onready var hurdle3_pointer = $Hurdle3
onready var hurdle4_pointer = $Hurdle4

var time_since_last_hurdle = 0

func _ready():
	var i = 1
	$Environment/Screen/Message.hide()
	
	for p in get_tree().get_nodes_in_group("players"):
		p.player_id = i
		i += 1
	
	spawn_hurdle()

func spawn_hurdle():
	var type = HURDLES[randi()%HURDLES.size()]
	
	var hurdle1 = type.instance()
	var hurdle2 = type.instance()
	var hurdle3 = type.instance()
	var hurdle4 = type.instance()
	
	hurdle1.translation = hurdle1_pointer.translation
	hurdle2.translation = hurdle2_pointer.translation
	hurdle3.translation = hurdle3_pointer.translation
	hurdle4.translation = hurdle4_pointer.translation
	
	add_child(hurdle1)
	add_child(hurdle2)
	add_child(hurdle3)
	add_child(hurdle4)

func spawn_powerup():
	var powerup = POWERUPS[randi() % POWERUPS.size()].instance()
	
	var position = [
		hurdle1_pointer.translation,
		hurdle2_pointer.translation,
		hurdle3_pointer.translation,
		hurdle4_pointer.translation
	]
	
	powerup.translation = position[randi() % position.size()]
	
	add_child(powerup)

func _process(delta):
	var current_time = $Ground/Mesh/Cube.get_surface_material(0).get_shader_param("delta_time")
	$Ground/Mesh/Cube.get_surface_material(0).set_shader_param("delta_time", current_time + delta)
	
	spawn_timer -= delta
	powerup_spawn_timer -= delta
	
	time_since_last_hurdle += delta
	
	if spawn_timer < 0:
		max_spawn -= 0.25
		
		if max_spawn < 1.0:
			max_spawn = 1.0
		
		spawn_timer = rand_range(1.0, max_spawn)
		
		spawn_hurdle()
		time_since_last_hurdle = 0
	
	# Prevent powerups from spawning inside hurdles
	if powerup_spawn_timer < 0 and time_since_last_hurdle > 0.1 and spawn_timer > 0.1:
		powerup_max_spawn -= 0.5
		
		if powerup_max_spawn < 0.5:
			powerup_max_spawn = 0.5
		
		powerup_spawn_timer = rand_range(1.0, powerup_max_spawn)
		
		spawn_powerup()
	
	var players = get_tree().get_nodes_in_group("players")
	for p in players:
		if p.translation.z < (-4 + p.player_id):
			losses += 1
			placement[4 - losses] = p.player_id # Assign placement before deleting player
			p.queue_free()
	
	if players.size() <= 1:
		# If the last player has not died yet, put him as the winner
		if players.size() == 1:
			placement[0] = players[0].player_id
		end_timer_start = true
		
		for p in Global.players:
			if p.player_id == placement[0]:
				$Environment/Screen/Message.text = tr("HURDLE_PLAYER_WINS_MSG").format({"player": p.player_name})
		
		$Environment/Screen/Message.show()
	
	if end_timer_start:
		end_timer -= delta
		if end_timer <= 0:
			Global.minigame_win_by_position(placement)
	else:
		timer -= delta
		
		if timer <= 0.0:
			end_timer_start = true
			timer = 0.0
			
			for p in players:
				p.stop = true
		
		$Environment/Screen/Timer.text = var2str(stepify(timer, 0.01))
