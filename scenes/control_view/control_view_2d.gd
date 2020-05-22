extends Control

func _ready():
	clear_display()

func display_action(action):
	clear_display()
	var conf = InputMap.get_action_list(action)[0]
	
	var control = ControlHelper.get_from_event(conf)
	if control is Texture:
		$TextureRect.texture = control
		$Label.text = ""
	else:
		if conf is InputEventKey:
			$TextureRect.texture = load("res://assets/textures/controls/keyboard/key_blank.png")
		else:
			$TextureRect.texture = null
		$Label.text = control

func clear_display():
	$Label.text = ""
	$TextureRect.texture = null
