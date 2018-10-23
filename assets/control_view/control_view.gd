extends Spatial

func _ready():
	clear_display()

func display_key(event):
	match event.scancode:
		KEY_UP:
			$Viewport/TextureRect.texture = load("res://assets/control_view/images/up.png")
		KEY_LEFT:
			$Viewport/TextureRect.texture = load("res://assets/control_view/images/left.png")
		KEY_DOWN:
			$Viewport/TextureRect.texture = load("res://assets/control_view/images/down.png")
		KEY_RIGHT:
			$Viewport/TextureRect.texture = load("res://assets/control_view/images/right.png")
		_:
			$Viewport/Label.text = OS.get_scancode_string(event.scancode)
			$Viewport/TextureRect.texture = load("res://assets/control_view/images/key_background.png")

func display_mouse_button(event):
	match event.button_index:
		BUTTON_LEFT:
			$Viewport/TextureRect.texture = load("res://assets/control_view/images/left_mouse.png")
		BUTTON_RIGHT:
			$Viewport/TextureRect.texture = load("res://assets/control_view/images/right_mouse.png")
		BUTTON_MIDDLE:
			$Viewport/TextureRect.texture = load("res://assets/control_view/images/middle_mouse.png")
		_:
			$Viewport/Label.text = "Mouse " + var2str(event.button_index)

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
					$Viewport/TextureRect.texture = load("res://assets/control_view/images/button3.png")
				Global.JOYPAD_DISPLAY_TYPE.XBOX:
					$Viewport/TextureRect.texture = load("res://assets/control_view/images/buttonA.png")
				Global.JOYPAD_DISPLAY_TYPE.NINTENDO_DS:
					$Viewport/TextureRect.texture = load("res://assets/control_view/images/buttonB.png")
				Global.JOYPAD_DISPLAY_TYPE.PLAYSTATION:
					$Viewport/TextureRect.texture = load("res://assets/control_view/images/buttonX.png")
		JOY_BUTTON_1:
			match Global.joypad_display:
				Global.JOYPAD_DISPLAY_TYPE.NUMBERS:
					$Viewport/TextureRect.texture = load("res://assets/control_view/images/button2.png")
				Global.JOYPAD_DISPLAY_TYPE.XBOX:
					$Viewport/TextureRect.texture = load("res://assets/control_view/images/buttonB.png")
				Global.JOYPAD_DISPLAY_TYPE.NINTENDO_DS:
					$Viewport/TextureRect.texture = load("res://assets/control_view/images/buttonA.png")
				Global.JOYPAD_DISPLAY_TYPE.PLAYSTATION:
					$Viewport/TextureRect.texture = load("res://assets/control_view/images/buttonCircle.png")
		JOY_BUTTON_2:
			match Global.joypad_display:
				Global.JOYPAD_DISPLAY_TYPE.NUMBERS:
					$Viewport/TextureRect.texture = load("res://assets/control_view/images/button4.png")
				Global.JOYPAD_DISPLAY_TYPE.XBOX:
					$Viewport/TextureRect.texture = load("res://assets/control_view/images/buttonX.png")
				Global.JOYPAD_DISPLAY_TYPE.NINTENDO_DS:
					$Viewport/TextureRect.texture = load("res://assets/control_view/images/buttonY.png")
				Global.JOYPAD_DISPLAY_TYPE.PLAYSTATION:
					$Viewport/TextureRect.texture = load("res://assets/control_view/images/buttonSquare.png")
		JOY_BUTTON_3:
			match Global.joypad_display:
				Global.JOYPAD_DISPLAY_TYPE.NUMBERS:
					$Viewport/TextureRect.texture = load("res://assets/control_view/images/button3.png")
				Global.JOYPAD_DISPLAY_TYPE.XBOX:
					$Viewport/TextureRect.texture = load("res://assets/control_view/images/buttonY.png")
				Global.JOYPAD_DISPLAY_TYPE.NINTENDO_DS:
					$Viewport/TextureRect.texture = load("res://assets/control_view/images/buttonX.png")
				Global.JOYPAD_DISPLAY_TYPE.PLAYSTATION:
					$Viewport/TextureRect.texture = load("res://assets/control_view/images/buttonTriangle.png")
		JOY_SELECT:
			$Viewport/TextureRect.texture = load("res://assets/control_view/images/buttonSelect.png")
		JOY_START:
			$Viewport/TextureRect.texture = load("res://assets/control_view/images/buttonStart.png")
		JOY_L2:
			$Viewport/TextureRect.texture = load("res://assets/control_view/images/buttonL.png")
		JOY_L:
			$Viewport/TextureRect.texture = load("res://assets/control_view/images/buttonL1.png")
		JOY_L3:
			$Viewport/TextureRect.texture = load("res://assets/control_view/images/buttonL2.png")
		JOY_R2:
			$Viewport/TextureRect.texture = load("res://assets/control_view/images/buttonR.png")
		JOY_R:
			$Viewport/TextureRect.texture = load("res://assets/control_view/images/buttonR1.png")
		JOY_R3:
			$Viewport/TextureRect.texture = load("res://assets/control_view/images/buttonR2.png")
		_:
			$Viewport/Label.text = "Joypad " + var2str(event.button_index)

func display_joypad_axis(event):
	match event.axis:
		JOY_ANALOG_LX:
			if event.axis_value < 0:
				$Viewport/TextureRect.texture = load("res://assets/control_view/images/arrowLeft.png")
			else:
				$Viewport/TextureRect.texture = load("res://assets/control_view/images/arrowRight.png")
		JOY_ANALOG_LY:
			if event.axis_value < 0:
				$Viewport/TextureRect.texture = load("res://assets/control_view/images/arrowUp.png")
			else:
				$Viewport/TextureRect.texture = load("res://assets/control_view/images/arrowDown.png")
		JOY_ANALOG_RX:
			if event.axis_value < 0:
				$Viewport/TextureRect.texture = load("res://assets/control_view/images/arrowLeft.png")
			else:
				$Viewport/TextureRect.texture = load("res://assets/control_view/images/arrowRight.png")
		JOY_ANALOG_RY:
			if event.axis_value < 0:
				$Viewport/TextureRect.texture = load("res://assets/control_view/images/arrowUp.png")
			else:
				$Viewport/TextureRect.texture = load("res://assets/control_view/images/arrowDown.png")
		JOY_ANALOG_L2:
			$Viewport/TextureRect.texture = load("res://assets/control_view/images/buttonL.png")
		JOY_ANALOG_R2:
			$Viewport/TextureRect.texture = load("res://assets/control_view/images/buttonR.png")
		_:
			if event.axis_value < 0:
				$Viewport/Label.text = "Axis -" + var2str(event.axis)
			else:
				$Viewport/Label.text = "Axis +" + var2str(event.axis)
	
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
	$Viewport/Label.text = ""
	$Viewport/TextureRect.texture = null