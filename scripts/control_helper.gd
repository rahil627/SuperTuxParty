
static func get_mousebutton_name(index):
	match index:
		BUTTON_LEFT:
			return "Left mouse button"
		BUTTON_RIGHT:
			return "Right mouse button"
		BUTTON_MIDDLE:
			return "Middle mouse button"
		BUTTON_WHEEL_UP:
			return "Button wheel up"
		BUTTON_WHEEL_DOWN:
			return "Button wheel down"
		BUTTON_WHEEL_LEFT:
			return "Button wheel left"
		BUTTON_WHEEL_RIGHT:
			return "Button wheel right"
		_:
			return "Mouse button " + var2str(index)

static func get_joypad_axis_name(axis, axis_value):
	var axis_name = "+"
	if axis_value < 0:
		axis_name = "-"
	
	match axis:
		JOY_ANALOG_LX:
			axis_name += "X Left"
		JOY_ANALOG_LY:
			axis_name += "Y Left"
		JOY_ANALOG_RX:
			axis_name += "X Right"
		JOY_ANALOG_RY:
			axis_name += "Y Right"
		JOY_ANALOG_L2:
			return "Trigger Left"
		JOY_ANALOG_R2:
			return "Trigger Right"
		_:
			axis_name += "Unknown Axis " + var2str(axis)
	
	return axis_name

static func get_joypad_button_name(button):
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
					return "Joypad button 3"
				Global.JOYPAD_DISPLAY_TYPE.XBOX:
					return "Joypad button A"
				Global.JOYPAD_DISPLAY_TYPE.NINTENDO_DS:
					return "Joypad button B"
				Global.JOYPAD_DISPLAY_TYPE.PLAYSTATION:
					return "Joypad button Cross"
		JOY_BUTTON_1:
			match Global.joypad_display:
				Global.JOYPAD_DISPLAY_TYPE.NUMBERS:
					return "Joypad button 2"
				Global.JOYPAD_DISPLAY_TYPE.XBOX:
					return "Joypad button B"
				Global.JOYPAD_DISPLAY_TYPE.NINTENDO_DS:
					return "Joypad button A"
				Global.JOYPAD_DISPLAY_TYPE.PLAYSTATION:
					return "Joypad button Circle"
		JOY_BUTTON_2:
			match Global.joypad_display:
				Global.JOYPAD_DISPLAY_TYPE.NUMBERS:
					return "Joypad button 4"
				Global.JOYPAD_DISPLAY_TYPE.XBOX:
					return "Joypad button X"
				Global.JOYPAD_DISPLAY_TYPE.NINTENDO_DS:
					return "Joypad button Y"
				Global.JOYPAD_DISPLAY_TYPE.PLAYSTATION:
					return "Joypad button Square"
		JOY_BUTTON_3:
			match Global.joypad_display:
				Global.JOYPAD_DISPLAY_TYPE.NUMBERS:
					return "Joypad button 1"
				Global.JOYPAD_DISPLAY_TYPE.XBOX:
					return "Joypad button Y"
				Global.JOYPAD_DISPLAY_TYPE.NINTENDO_DS:
					return "Joypad button X"
				Global.JOYPAD_DISPLAY_TYPE.PLAYSTATION:
					return "Joypad button Triangle"
		JOY_L:
			return "Left Trigger"
		JOY_L2:
			return "Left Trigger 2"
		JOY_L3:
			return "Left Trigger 3"
		JOY_R:
			return "Right Trigger"
		JOY_R2:
			return "Right Trigger 2"
		JOY_R3:
			return "Right Trigger 3"
		JOY_START:
			return "Joypad Start"
		JOY_SELECT:
			return "Joypad Select"
	
	return "Joypad button " + var2str(button)

static func get_button_name(event):
	if event is InputEventKey:
		return OS.get_scancode_string(event.scancode)
	elif event is InputEventMouseButton:
		return get_mousebutton_name(event.button_index)
	elif event is InputEventJoypadMotion:
		return "Joypad " + get_joypad_axis_name(event.axis, event.axis_value)
	elif event is InputEventJoypadButton:
		return get_joypad_button_name(event.button_index)
	else:
		return "Unknown"
