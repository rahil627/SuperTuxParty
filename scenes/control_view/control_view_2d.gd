extends Control

func _ready():
	clear_display()

func display_key(event):
	match event.scancode:
		KEY_UP:
			$TextureRect.texture = load("res://assets/textures/controls/keyboard/up.png")
		KEY_LEFT:
			$TextureRect.texture = load("res://assets/textures/controls/keyboard/left.png")
		KEY_DOWN:
			$TextureRect.texture = load("res://assets/textures/controls/keyboard/down.png")
		KEY_RIGHT:
			$TextureRect.texture = load("res://assets/textures/controls/keyboard/right.png")
		KEY_TAB:
			$TextureRect.texture = load("res://assets/textures/controls/keyboard/tab.png")
		KEY_SHIFT:
			$TextureRect.texture = load("res://assets/textures/controls/keyboard/shift.png")
		KEY_ALT:
			$TextureRect.texture = load("res://assets/textures/controls/keyboard/alt.png")
		KEY_CAPSLOCK:
			$TextureRect.texture = load("res://assets/textures/controls/keyboard/caps.png")
		KEY_CONTROL:
			$TextureRect.texture = load("res://assets/textures/controls/keyboard/control.png")
		KEY_ENTER:
			$TextureRect.texture = load("res://assets/textures/controls/keyboard/enter.png")
		KEY_SPACE:
			$TextureRect.texture = load("res://assets/textures/controls/keyboard/space.png")
		KEY_ESCAPE:
			$TextureRect.texture = load("res://assets/textures/controls/keyboard/escape.png")
		KEY_NUMLOCK:
			$TextureRect.texture = load("res://assets/textures/controls/keyboard/numlock.png")
		KEY_KP_0:
			$TextureRect.texture = load("res://assets/textures/controls/keyboard/kp_0.png")
		KEY_KP_1:
			$TextureRect.texture = load("res://assets/textures/controls/keyboard/kp_1.png")
		KEY_KP_2:
			$TextureRect.texture = load("res://assets/textures/controls/keyboard/kp_2.png")
		KEY_KP_3:
			$TextureRect.texture = load("res://assets/textures/controls/keyboard/kp_3.png")
		KEY_KP_4:
			$TextureRect.texture = load("res://assets/textures/controls/keyboard/kp_4.png")
		KEY_KP_5:
			$TextureRect.texture = load("res://assets/textures/controls/keyboard/kp_5.png")
		KEY_KP_6:
			$TextureRect.texture = load("res://assets/textures/controls/keyboard/kp_6.png")
		KEY_KP_7:
			$TextureRect.texture = load("res://assets/textures/controls/keyboard/kp_7.png")
		KEY_KP_8:
			$TextureRect.texture = load("res://assets/textures/controls/keyboard/kp_8.png")
		KEY_KP_9:
			$TextureRect.texture = load("res://assets/textures/controls/keyboard/kp_9.png")
		KEY_KP_ADD:
			$TextureRect.texture = load("res://assets/textures/controls/keyboard/kp_plus.png")
		KEY_KP_DIVIDE:
			$TextureRect.texture = load("res://assets/textures/controls/keyboard/kp_slash.png")
		KEY_KP_ENTER:
			$TextureRect.texture = load("res://assets/textures/controls/keyboard/kp_enter.png")
		KEY_KP_MULTIPLY:
			$TextureRect.texture = load("res://assets/textures/controls/keyboard/kp_asterisk.png")
		KEY_KP_PERIOD:
			$TextureRect.texture = load("res://assets/textures/controls/keyboard/kp_period.png")
		KEY_KP_SUBTRACT:
			$TextureRect.texture = load("res://assets/textures/controls/keyboard/kp_minus.png")
		_:
			if event.scancode < 127:
				# Scancodes < 127 are actually ASCII
				$Label.text = char(event.scancode)
			else:
				# TODO: Support for non-ascii keys
				$Label.text = OS.get_scancode_string(event.scancode)
			$TextureRect.texture = load("res://assets/textures/controls/keyboard/key_blank.png")

func display_mouse_button(event):
	match event.button_index:
		BUTTON_LEFT:
			$TextureRect.texture = load("res://assets/textures/controls/mouse/left_mouse.png")
		BUTTON_RIGHT:
			$TextureRect.texture = load("res://assets/textures/controls/mouse/right_mouse.png")
		BUTTON_MIDDLE:
			$TextureRect.texture = load("res://assets/textures/controls/mouse/middle_mouse.png")
		_:
			$Label.text = tr("MENU_CONTROLS_MOUSE") + " " + var2str(event.button_index)

func display_joypad_button(event):
	match event.button_index:
		JOY_BUTTON_0:
			$TextureRect.texture = load("res://assets/textures/controls/gamepad/button_down.png")
		JOY_BUTTON_1:
			$TextureRect.texture = load("res://assets/textures/controls/gamepad/button_right.png")
		JOY_BUTTON_2:
			$TextureRect.texture = load("res://assets/textures/controls/gamepad/button_left.png")
		JOY_BUTTON_3:
			$TextureRect.texture = load("res://assets/textures/controls/gamepad/button_up.png")
		JOY_SELECT:
			$TextureRect.texture = load("res://assets/textures/controls/gamepad/buttonSelect.png")
		JOY_START:
			$TextureRect.texture = load("res://assets/textures/controls/gamepad/buttonStart.png")
		JOY_L:
			$TextureRect.texture = load("res://assets/textures/controls/gamepad/buttonL.png")
		JOY_R:
			$TextureRect.texture = load("res://assets/textures/controls/gamepad/buttonR.png")
		_:
			$Label.text = tr("MENU_CONTROLS_GAMEPAD") + " " + var2str(event.button_index)

func display_joypad_axis(event):
	match event.axis:
		JOY_ANALOG_LX:
			if event.axis_value < 0:
				$TextureRect.texture = load("res://assets/textures/controls/gamepad/arrowLeft.png")
			else:
				$TextureRect.texture = load("res://assets/textures/controls/gamepad/arrowRight.png")
		JOY_ANALOG_LY:
			if event.axis_value < 0:
				$TextureRect.texture = load("res://assets/textures/controls/gamepad/arrowUp.png")
			else:
				$TextureRect.texture = load("res://assets/textures/controls/gamepad/arrowDown.png")
		JOY_ANALOG_RX:
			if event.axis_value < 0:
				$TextureRect.texture = load("res://assets/textures/controls/gamepad/arrowLeft.png")
			else:
				$TextureRect.texture = load("res://assets/textures/controls/gamepad/arrowRight.png")
		JOY_ANALOG_RY:
			if event.axis_value < 0:
				$TextureRect.texture = load("res://assets/textures/controls/gamepad/arrowUp.png")
			else:
				$TextureRect.texture = load("res://assets/textures/controls/gamepad/arrowDown.png")
		JOY_ANALOG_L2:
			$TextureRect.texture = load("res://assets/textures/controls/gamepad/buttonL.png")
		JOY_ANALOG_R2:
			$TextureRect.texture = load("res://assets/textures/controls/gamepad/buttonR.png")
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
