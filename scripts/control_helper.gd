extends Node

func get_mousebutton_name(index):
	match index:
		BUTTON_LEFT:
			return tr("MENU_CONTROLS_MOUSE_BUTTON_LEFT")
		BUTTON_RIGHT:
			return tr("MENU_CONTROLS_MOUSE_BUTTON_RIGHT")
		BUTTON_MIDDLE:
			return tr("MENU_CONTROLS_MOUSE_BUTTON_MIDDLE")
		BUTTON_WHEEL_UP:
			return tr("MENU_CONTROLS_WHEEL_UP")
		BUTTON_WHEEL_DOWN:
			return tr("MENU_CONTROLS_WHEEL_DOWN")
		BUTTON_WHEEL_LEFT:
			return tr("MENU_CONTROLS_WHEEL_LEFT")
		BUTTON_WHEEL_RIGHT:
			return tr("MENU_CONTROLS_WHEEL_RIGHT")
		_:
			return tr("MENU_CONTROLS_MOUSE_BUTTON") + " " + var2str(index)

func get_joypad_axis_name(axis, axis_value):
	var axis_name = "+"
	if axis_value < 0:
		axis_name = "-"
	
	match axis:
		JOY_ANALOG_LX:
			axis_name += tr("MENU_CONTROLS_AXIS_X_LEFT")
		JOY_ANALOG_LY:
			axis_name += tr("MENU_CONTROLS_AXIS_Y_LEFT")
		JOY_ANALOG_RX:
			axis_name += tr("MENU_CONTROLS_AXIS_X_RIGHT")
		JOY_ANALOG_RY:
			axis_name += tr("MENU_CONTROLS_AXIS_Y_RIGHT")
		JOY_ANALOG_L2:
			return tr("MENU_CONTROLS_TRIGGER_LEFT")
		JOY_ANALOG_R2:
			return tr("MENU_CONTROLS_TRIGGER_RIGHT")
		_:
			axis_name += tr("MENU_CONTROLS_AXIS_UNKNOWN") + " " + var2str(axis)
	
	return axis_name

func get_joypad_button_name(button):
	# Joystick button indizes:
	#      3
	#    2   1
	#      0
	# How it will be displayed (depending on Game Options):
	#   Numbers:    XBOX:      DS:      PS:
	#      1          Y         X        /\
	#    4   2      X   B     Y   A   []    ()
	#      3          A         B        X
	match button:
		JOY_BUTTON_0:
			match Global.joypad_display:
				Global.JOYPAD_DISPLAY_TYPE.NUMBERS:
					return tr("MENU_CONTROLS_GAMEPAD_BUTTON_3")
				Global.JOYPAD_DISPLAY_TYPE.XBOX:
					return tr("MENU_CONTROLS_GAMEPAD_BUTTON_A")
				Global.JOYPAD_DISPLAY_TYPE.NINTENDO_DS:
					return tr("MENU_CONTROLS_GAMEPAD_BUTTON_B")
				Global.JOYPAD_DISPLAY_TYPE.PLAYSTATION:
					return tr("MENU_CONTROLS_GAMEPAD_BUTTON_CROSS")
		JOY_BUTTON_1:
			match Global.joypad_display:
				Global.JOYPAD_DISPLAY_TYPE.NUMBERS:
					return tr("MENU_CONTROLS_GAMEPAD_BUTTON_2")
				Global.JOYPAD_DISPLAY_TYPE.XBOX:
					return tr("MENU_CONTROLS_GAMEPAD_BUTTON_B")
				Global.JOYPAD_DISPLAY_TYPE.NINTENDO_DS:
					return tr("MENU_CONTROLS_GAMEPAD_BUTTON_A")
				Global.JOYPAD_DISPLAY_TYPE.PLAYSTATION:
					return tr("MENU_CONTROLS_GAMEPAD_BUTTON_CIRCLE")
		JOY_BUTTON_2:
			match Global.joypad_display:
				Global.JOYPAD_DISPLAY_TYPE.NUMBERS:
					return tr("MENU_CONTROLS_GAMEPAD_BUTTON_4")
				Global.JOYPAD_DISPLAY_TYPE.XBOX:
					return tr("MENU_CONTROLS_GAMEPAD_BUTTON_X")
				Global.JOYPAD_DISPLAY_TYPE.NINTENDO_DS:
					return tr("MENU_CONTROLS_GAMEPAD_BUTTON_Y")
				Global.JOYPAD_DISPLAY_TYPE.PLAYSTATION:
					return tr("MENU_CONTROLS_GAMEPAD_BUTTON_SQUARE")
		JOY_BUTTON_3:
			match Global.joypad_display:
				Global.JOYPAD_DISPLAY_TYPE.NUMBERS:
					return tr("MENU_CONTROLS_GAMEPAD_BUTTON_1")
				Global.JOYPAD_DISPLAY_TYPE.XBOX:
					return tr("MENU_CONTROLS_GAMEPAD_BUTTON_Y")
				Global.JOYPAD_DISPLAY_TYPE.NINTENDO_DS:
					return tr("MENU_CONTROLS_GAMEPAD_BUTTON_X")
				Global.JOYPAD_DISPLAY_TYPE.PLAYSTATION:
					return tr("MENU_CONTROLS_GAMEPAD_BUTTON_TRIANGLE")
		JOY_L:
			return tr("MENU_CONTROLS_TRIGGER_LEFT")
		JOY_L2:
			return tr("MENU_CONTROLS_TRIGGER_LEFT_2")
		JOY_L3:
			return tr("MENU_CONTROLS_TRIGGER_LEFT_3")
		JOY_R:
			return tr("MENU_CONTROLS_TRIGGER_RIGHT")
		JOY_R2:
			return tr("MENU_CONTROLS_TRIGGER_RIGHT_2")
		JOY_R3:
			return tr("MENU_CONTROLS_TRIGGER_RIGHT_3")
		JOY_START:
			return tr("MENU_CONTROLS_GAMEPAD_START")
		JOY_SELECT:
			return tr("MENU_CONTROLS_GAMEPAD_SELECT")
	
	return tr("MENU_CONTROLS_GAMEPAD_BUTTON") + " " + var2str(button)

func get_button_name(event):
	if event is InputEventKey:
		return OS.get_scancode_string(event.scancode)
	elif event is InputEventMouseButton:
		return get_mousebutton_name(event.button_index)
	elif event is InputEventJoypadMotion:
		return tr("MENU_CONTROLS_GAMEPAD") + " " + get_joypad_axis_name(event.axis, event.axis_value)
	elif event is InputEventJoypadButton:
		return get_joypad_button_name(event.button_index)
	else:
		return tr("MENU_CONTROLS_BUTTON_UNKNOWN")
