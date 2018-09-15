
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
