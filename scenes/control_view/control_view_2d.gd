extends Control

func _ready():
	clear_display()

func display_key(event):
	match event.scancode:
		KEY_UP:
			$TextureRect.texture = load("res://assets/textures/controls/up.png")
		KEY_LEFT:
			$TextureRect.texture = load("res://assets/textures/controls/left.png")
		KEY_DOWN:
			$TextureRect.texture = load("res://assets/textures/controls/down.png")
		KEY_RIGHT:
			$TextureRect.texture = load("res://assets/textures/controls/right.png")
		_:
			$Label.text = OS.get_scancode_string(event.scancode)
			$TextureRect.texture = load("res://assets/textures/controls/key_background.png")

func display_mouse_button(event):
	match event.button_index:
		BUTTON_LEFT:
			$TextureRect.texture = load("res://assets/textures/controls/left_mouse.png")
		BUTTON_RIGHT:
			$TextureRect.texture = load("res://assets/textures/controls/right_mouse.png")
		BUTTON_MIDDLE:
			$TextureRect.texture = load("res://assets/textures/controls/middle_mouse.png")
		_:
			$Label.text = tr("MENU_CONTROLS_MOUSE") + " " + var2str(event.button_index)

func display_joypad_button(event):
	match event.button_index:
		# Joystick button indizes:
		#      3
		#    2   1
		#      0
		# How it will be displayed (depending on Game Options):
		#   Numbers:    XBOX:      DS:      PS:
		#      1          Y         X        /\
		#    4   2      X   B     Y   A   []    ()
		#      3          A         B        X
		JOY_BUTTON_0:
			match Global.joypad_display:
				Global.JOYPAD_DISPLAY_TYPE.NUMBERS:
					$TextureRect.texture = load("res://assets/textures/controls/button3.png")
				Global.JOYPAD_DISPLAY_TYPE.XBOX:
					$TextureRect.texture = load("res://assets/textures/controls/buttonA.png")
				Global.JOYPAD_DISPLAY_TYPE.NINTENDO_DS:
					$TextureRect.texture = load("res://assets/textures/controls/buttonB.png")
				Global.JOYPAD_DISPLAY_TYPE.PLAYSTATION:
					$TextureRect.texture = load("res://assets/textures/controls/buttonX.png")
		JOY_BUTTON_1:
			match Global.joypad_display:
				Global.JOYPAD_DISPLAY_TYPE.NUMBERS:
					$TextureRect.texture = load("res://assets/textures/controls/button2.png")
				Global.JOYPAD_DISPLAY_TYPE.XBOX:
					$TextureRect.texture = load("res://assets/textures/controls/buttonB.png")
				Global.JOYPAD_DISPLAY_TYPE.NINTENDO_DS:
					$TextureRect.texture = load("res://assets/textures/controls/buttonA.png")
				Global.JOYPAD_DISPLAY_TYPE.PLAYSTATION:
					$TextureRect.texture = load("res://assets/textures/controls/buttonCircle.png")
		JOY_BUTTON_2:
			match Global.joypad_display:
				Global.JOYPAD_DISPLAY_TYPE.NUMBERS:
					$TextureRect.texture = load("res://assets/textures/controls/button4.png")
				Global.JOYPAD_DISPLAY_TYPE.XBOX:
					$TextureRect.texture = load("res://assets/textures/controls/buttonX.png")
				Global.JOYPAD_DISPLAY_TYPE.NINTENDO_DS:
					$TextureRect.texture = load("res://assets/textures/controls/buttonY.png")
				Global.JOYPAD_DISPLAY_TYPE.PLAYSTATION:
					$TextureRect.texture = load("res://assets/textures/controls/buttonSquare.png")
		JOY_BUTTON_3:
			match Global.joypad_display:
				Global.JOYPAD_DISPLAY_TYPE.NUMBERS:
					$TextureRect.texture = load("res://assets/textures/controls/button3.png")
				Global.JOYPAD_DISPLAY_TYPE.XBOX:
					$TextureRect.texture = load("res://assets/textures/controls/buttonY.png")
				Global.JOYPAD_DISPLAY_TYPE.NINTENDO_DS:
					$TextureRect.texture = load("res://assets/textures/controls/buttonX.png")
				Global.JOYPAD_DISPLAY_TYPE.PLAYSTATION:
					$TextureRect.texture = load("res://assets/textures/controls/buttonTriangle.png")
		JOY_SELECT:
			$TextureRect.texture = load("res://assets/textures/controls/buttonSelect.png")
		JOY_START:
			$TextureRect.texture = load("res://assets/textures/controls/buttonStart.png")
		JOY_L2:
			$TextureRect.texture = load("res://assets/textures/controls/buttonL.png")
		JOY_L:
			$TextureRect.texture = load("res://assets/textures/controls/buttonL1.png")
		JOY_L3:
			$TextureRect.texture = load("res://assets/textures/controls/buttonL2.png")
		JOY_R2:
			$TextureRect.texture = load("res://assets/textures/controls/buttonR.png")
		JOY_R:
			$TextureRect.texture = load("res://assets/textures/controls/buttonR1.png")
		JOY_R3:
			$TextureRect.texture = load("res://assets/textures/controls/buttonR2.png")
		_:
			$Label.text = tr("MENU_CONTROLS_GAMEPAD") + " " + var2str(event.button_index)

func display_joypad_axis(event):
	match event.axis:
		JOY_ANALOG_LX:
			if event.axis_value < 0:
				$TextureRect.texture = load("res://assets/textures/controls/arrowLeft.png")
			else:
				$TextureRect.texture = load("res://assets/textures/controls/arrowRight.png")
		JOY_ANALOG_LY:
			if event.axis_value < 0:
				$TextureRect.texture = load("res://assets/textures/controls/arrowUp.png")
			else:
				$TextureRect.texture = load("res://assets/textures/controls/arrowDown.png")
		JOY_ANALOG_RX:
			if event.axis_value < 0:
				$TextureRect.texture = load("res://assets/textures/controls/arrowLeft.png")
			else:
				$TextureRect.texture = load("res://assets/textures/controls/arrowRight.png")
		JOY_ANALOG_RY:
			if event.axis_value < 0:
				$TextureRect.texture = load("res://assets/textures/controls/arrowUp.png")
			else:
				$TextureRect.texture = load("res://assets/textures/controls/arrowDown.png")
		JOY_ANALOG_L2:
			$TextureRect.texture = load("res://assets/textures/controls/buttonL.png")
		JOY_ANALOG_R2:
			$TextureRect.texture = load("res://assets/textures/controls/buttonR.png")
		_:
			if event.axis_value < 0:
				$Label.text = tr("MENU_CONTROLS_AXIS_MINUS") + var2str(event.axis)
			else:
				$Label.text = tr("MENU_CONTROLS_AXIS_PLUS") + var2str(event.axis)
	
	return name

func display_action(action):
	clear_display()
	var conf = InputMap.get_action_list(action)[0]
	
	if conf is InputEventKey:
		display_key(conf)
	elif conf is InputEventMouseButton:
		display_mouse_button(conf)
	elif conf is InputEventJoypadButton:
		display_joypad_button(conf)
	elif conf is InputEventJoypadMotion:
		display_joypad_axis(conf)

func clear_display():
	$Label.text = ""
	$TextureRect.texture = null