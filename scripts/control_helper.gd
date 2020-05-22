extends Node

func get_from_key(event: InputEventKey):
	match event.scancode:
		KEY_UP:
			return load("res://assets/textures/controls/keyboard/up.png")
		KEY_LEFT:
			return load("res://assets/textures/controls/keyboard/left.png")
		KEY_DOWN:
			return load("res://assets/textures/controls/keyboard/down.png")
		KEY_RIGHT:
			return load("res://assets/textures/controls/keyboard/right.png")
		KEY_ALT:
			return load("res://assets/textures/controls/keyboard/alt.png")
		KEY_CAPSLOCK:
			return load("res://assets/textures/controls/keyboard/caps.png")
		KEY_CONTROL:
			return load("res://assets/textures/controls/keyboard/control.png")
		KEY_ENTER:
			return load("res://assets/textures/controls/keyboard/enter.png")
		KEY_ESCAPE:
			return load("res://assets/textures/controls/keyboard/escape.png")
		KEY_KP_0:
			return load("res://assets/textures/controls/keyboard/kp_0.png")
		KEY_KP_1:
			return load("res://assets/textures/controls/keyboard/kp_1.png")
		KEY_KP_2:
			return load("res://assets/textures/controls/keyboard/kp_2.png")
		KEY_KP_3:
			return load("res://assets/textures/controls/keyboard/kp_3.png")
		KEY_KP_4:
			return load("res://assets/textures/controls/keyboard/kp_4.png")
		KEY_KP_5:
			return load("res://assets/textures/controls/keyboard/kp_5.png")
		KEY_KP_6:
			return load("res://assets/textures/controls/keyboard/kp_6.png")
		KEY_KP_7:
			return load("res://assets/textures/controls/keyboard/kp_7.png")
		KEY_KP_8:
			return load("res://assets/textures/controls/keyboard/kp_8.png")
		KEY_KP_9:
			return load("res://assets/textures/controls/keyboard/kp_9.png")
		KEY_KP_MULTIPLY:
			return load("res://assets/textures/controls/keyboard/kp_asterisk.png")
		KEY_KP_ENTER:
			return load("res://assets/textures/controls/keyboard/kp_enter.png")
		KEY_KP_SUBTRACT:
			return load("res://assets/textures/controls/keyboard/kp_minus.png")
		KEY_KP_PERIOD:
			return load("res://assets/textures/controls/keyboard/kp_period.png")
		KEY_KP_ADD:
			return load("res://assets/textures/controls/keyboard/kp_plus.png")
		KEY_KP_DIVIDE:
			return load("res://assets/textures/controls/keyboard/kp_slash.png")
		KEY_NUMLOCK:
			return load("res://assets/textures/controls/keyboard/numlock.png")
		KEY_SHIFT:
			return load("res://assets/textures/controls/keyboard/shift.png")
		KEY_SPACE:
			return load("res://assets/textures/controls/keyboard/space.png")
		KEY_TAB:
			return load("res://assets/textures/controls/keyboard/tab.png")
	if event.scancode < 127 and event.scancode != KEY_SPACE:
		# Scancodes < 127 are actually ASCII
		return char(event.scancode)
	else:
		# TODO: Display non-ascii keys with their respective chars instead
		# of their name
		return OS.get_scancode_string(event.scancode)

func get_from_mouse_button(event: InputEventMouseButton):
	match event.button_index:
		BUTTON_LEFT:
			return load("res://assets/textures/controls/mouse/left_mouse.png")
		BUTTON_RIGHT:
			return load("res://assets/textures/controls/mouse/right_mouse.png")
		BUTTON_MIDDLE:
			return load("res://assets/textures/controls/mouse/middle_mouse.png")
		BUTTON_WHEEL_UP:
			return tr("MENU_CONTROLS_MOUSE_WHEEL_UP")
		BUTTON_WHEEL_DOWN:
			return tr("MENU_CONTROLS_MOUSE_WHEEL_DOWN")
		BUTTON_WHEEL_LEFT:
			return tr("MENU_CONTROLS_MOUSE_WHEEL_LEFT")
		BUTTON_WHEEL_RIGHT:
			return tr("MENU_CONTROLS_MOUSE_WHEEL_RIGHT")
		_:
			return tr("MENU_CONTROLS_MOUSE_BUTTON").format({"button": event.button_index})

func get_from_joypad_axis(event: InputEventJoypadMotion):
	match event.axis:
		JOY_ANALOG_LX:
			if event.axis_value > 0:
				return load("res://assets/textures/controls/gamepad/arrowRight.png")
			else:
				return load("res://assets/textures/controls/gamepad/arrowLeft.png")
		JOY_ANALOG_LY:
			if event.axis_value > 0:
				return load("res://assets/textures/controls/gamepad/arrowDown.png")
			else:
				return load("res://assets/textures/controls/gamepad/arrowUp.png")
		JOY_ANALOG_RX:
			if event.axis_value > 0:
				return load("res://assets/textures/controls/gamepad/arrowRight.png")
			else:
				return load("res://assets/textures/controls/gamepad/arrowLeft.png")
		JOY_ANALOG_RY:
			if event.axis_value > 0:
				return load("res://assets/textures/controls/gamepad/arrowDown.png")
			else:
				return load("res://assets/textures/controls/gamepad/arrowUp.png")
		JOY_ANALOG_L2:
			return load("res://assets/textures/controls/gamepad/buttonL.png")
		JOY_ANALOG_R2:
			return load("res://assets/textures/controls/gamepad/buttonL.png")
		_:
			return tr("MENU_CONTROLS_UNKNOWN_GAMEPAD_AXIS").format({"axis": event.axis, "sign": "-" if event.axis_value < 0 else "+"})

func get_from_joypad_button(event: InputEventJoypadButton):
	match event.button_index:
		JOY_BUTTON_0:
			return load("res://assets/textures/controls/gamepad/button_down.png")
		JOY_BUTTON_1:
			return load("res://assets/textures/controls/gamepad/button_right.png")
		JOY_BUTTON_2:
			return load("res://assets/textures/controls/gamepad/button_left.png")
		JOY_BUTTON_3:
			return load("res://assets/textures/controls/gamepad/button_up.png")
		JOY_DPAD_LEFT:
			return load("res://assets/textures/controls/gamepad/dpad_left.png")
		JOY_DPAD_RIGHT:
			return load("res://assets/textures/controls/gamepad/dpad_right.png")
		JOY_DPAD_DOWN:
			return load("res://assets/textures/controls/gamepad/dpad_down.png")
		JOY_DPAD_UP:
			return load("res://assets/textures/controls/gamepad/dpad_up.png")
		JOY_SELECT:
			return load("res://assets/textures/controls/gamepad/buttonSelect.png")
		JOY_START:
			return load("res://assets/textures/controls/gamepad/buttonStart.png")
		JOY_L:
			return load("res://assets/textures/controls/gamepad/buttonL.png")
		JOY_R:
			return load("res://assets/textures/controls/gamepad/buttonR.png")
		_:
			return tr("MENU_CONTROLS_GENERIC_GAMEPAD_BUTTON").format({"button": event.button_index})

func get_from_event(event: InputEvent):
	if event is InputEventKey:
		return get_from_key(event)
	elif event is InputEventMouseButton:
		return get_from_mouse_button(event)
	elif event is InputEventJoypadMotion:
		return get_from_joypad_axis(event)
	elif event is InputEventJoypadButton:
		return get_from_joypad_button(event)

func set_button(button: Button, value):
	if value is String:
		button.text = value
		button.icon = null
	elif value is Texture:
		button.icon = value
		button.text = ""

func set_button_to_event(button: Button, event: InputEvent):
	set_button(button, get_from_event(event))
