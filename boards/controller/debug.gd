extends WindowDialog

enum STATES {
	addCookies,
	addCakes,
	gotoPlayer
}

var players = null
var state = null

func setup():
	players = get_tree().get_nodes_in_group("players")
	
	for p in players:
		var button = Button.new()
		
		button.text = p.player_name
		button.add_font_override("font", preload("res://fonts/button_font.tres"))
		button.connect("pressed", self, "_on_player_pressed", [p.player_id])
		
		$List/Players.add_child(button)
	
	var loader = $"/root/Global".minigame_loader
	
	for game in loader.minigames_duel:
		var button = Button.new()
		
		button.text = game
		button.add_font_override("font", preload("res://fonts/button_font.tres"))
		button.connect("pressed", self, "_on_minigame_pressed", [button.text])
		
		$List/Minigames.add_child(button)
	
	for game in loader.minigames_1v3:
		var button = Button.new()
		
		button.text = game
		button.add_font_override("font", preload("res://fonts/button_font.tres"))
		button.connect("pressed", self, "_on_minigame_pressed", [button.text])
		
		$List/Minigames.add_child(button)
		
	for game in loader.minigames_2v2:
		var button = Button.new()
		
		button.text = game
		button.add_font_override("font", preload("res://fonts/button_font.tres"))
		button.connect("pressed", self, "_on_minigame_pressed", [button.text])
		
		$List/Minigames.add_child(button)
	
	for game in loader.minigames_ffa:
		var button = Button.new()
		
		button.text = game
		button.add_font_override("font", preload("res://fonts/button_font.tres"))
		button.connect("pressed", self, "_on_minigame_pressed", [button.text])
		
		$List/Minigames.add_child(button)

func _on_Skip_pressed():
	$"/root/Global".turn += 1
	$"../Turn".text = "Turn: " + var2str($"/root/Global".turn)

func _on_AddCookies_pressed():
	$List/Players.show()
	$List/Minigames.hide()
	$List.popup()
	
	state = STATES.addCookies

func _on_AddCake_pressed():
	$List/Players.show()
	$List/Minigames.hide()
	$List.popup()
	
	state = STATES.addCakes

func _on_PlayersTurn_pressed():
	$List/Players.show()
	$List/Minigames.hide()
	$List.popup()
	
	state = STATES.gotoPlayer

func _on_Minigame_pressed():
	$List/Players.hide()
	$List/Minigames.show()
	$List.popup()

func _on_player_pressed(id):
	var player = players[id - 1]
	
	if state == STATES.addCookies:
		player.cookies += 5
	elif state == STATES.addCakes:
		player.cakes += 1
	elif state == STATES.gotoPlayer:
		$"../..".player_turn = player.player_id
	
	$"../..".update_player_info()

func _on_minigame_pressed(minigame):
	$"/root/Global".goto_minigame(minigame)