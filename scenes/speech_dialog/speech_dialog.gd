extends Control

#warning-ignore: unused_signal
signal dialog_finished
#warning-ignore: unused_signal
signal dialog_option_taken(accepted)

const CLICK_SOUND = preload("res://assets/sounds/ui/rollover2.wav")
const SELECT_SOUND = preload("res://assets/sounds/ui/click1.wav")

var player_id: int

var is_notification: bool

func _ready() -> void:
	hide()

func _accept_dialog(type: String, data):
	hide()
	$HBoxContainer/NinePatchRect/Buttons.hide()
	$HBoxContainer/NinePatchRect/Range.hide()
	is_notification = false
	UISound.stream = CLICK_SOUND
	UISound.play()
	emit_signal(type, data)

func _ok_event():
	if has_focus() and is_notification:
		var scrollbar = $HBoxContainer/NinePatchRect/MarginContainer/Text.get_v_scroll()
		var height = $HBoxContainer/NinePatchRect/MarginContainer/Text.rect_size.y
		if scrollbar.value < scrollbar.max_value - height:
			scrollbar.value += height
		else:
			_accept_dialog("dialog_finished", null)
	elif $HBoxContainer/NinePatchRect/Buttons/Yes.has_focus():
		_accept_dialog("dialog_option_taken", true)
	elif $HBoxContainer/NinePatchRect/Buttons/No.has_focus():
		_accept_dialog("dialog_option_taken", false)
	elif $HBoxContainer/NinePatchRect/Range.visible:
		_accept_dialog("dialog_option_taken", $HBoxContainer/NinePatchRect/Range.value)


func _input(event: InputEvent) -> void:
	if not visible:
		return
	var is_action: bool = event.is_action_pressed("player%d_ok" % player_id)
	if is_action:
		get_tree().set_input_as_handled()
		_ok_event()
	var is_up: bool = event.is_action_pressed("player%d_up" % player_id)
	var is_down: bool = event.is_action_pressed("player%d_down" % player_id)
	if is_up or is_down:
		if $HBoxContainer/NinePatchRect/Range.visible:
			get_tree().set_input_as_handled()
			if is_up:
				$HBoxContainer/NinePatchRect/Range.value += 1
			else:
				$HBoxContainer/NinePatchRect/Range.value -= 1

func _setup(speaker: String, texture: Texture, text: String, player_id: int):
	$HBoxContainer/TextureRect.texture = texture
	self.player_id = player_id
	show()
	$HBoxContainer/NinePatchRect/Name.text = speaker
	$HBoxContainer/NinePatchRect/MarginContainer/Text.bbcode_text = text

func show_dialog(speaker: String, texture: Texture, text: String, player_id: int) -> void:
	_setup(speaker, texture, text, player_id)
	grab_focus()
	is_notification = true
	
	if Global.players[player_id - 1].is_ai:
		get_tree().create_timer(2).connect("timeout", self, "_accept_dialog", ["dialog_finished", null])

func show_accept_dialog(speaker: String, texture: Texture, text: String, player_id: int, ai_default: bool) -> void:
	_setup(speaker, texture, text, player_id)
	$HBoxContainer/NinePatchRect/Buttons.show()
	$HBoxContainer/NinePatchRect/Buttons/Yes.grab_focus()
	
	if Global.players[player_id - 1].is_ai:
		get_tree().create_timer(2).connect("timeout", self, "_accept_dialog", ["dialog_option_taken", ai_default])

func show_query_dialog(speaker: String, texture: Texture, text: String, player_id: int, minimum: int, maximum: int, start_value: int, ai_default: int):
	_setup(speaker, texture, text, player_id)
	$HBoxContainer/NinePatchRect/Range.min_value = minimum
	$HBoxContainer/NinePatchRect/Range.max_value = maximum
	$HBoxContainer/NinePatchRect/Range.value = start_value
	$HBoxContainer/NinePatchRect/Range.show()
	
	if Global.players[player_id - 1].is_ai:
		get_tree().create_timer(2).connect("timeout", self, "_accept_dialog", ["dialog_option_taken", ai_default])

func _on_focus_entered(node: String) -> void:
	(get_node(node) as NinePatchRect).texture = load("res://scenes/speech_dialog/dialog_box_focus.png")

func _on_focus_exited(node: String) -> void:
	(get_node(node) as NinePatchRect).texture = load("res://scenes/speech_dialog/dialog_box.png")
	UISound.stream = SELECT_SOUND
	UISound.play()

func _on_mouse_entered(node: String) -> void:
	_on_focus_entered(node)

func _on_mouse_exited(node: String) -> void:
	if not get_node(node).has_focus():
		_on_focus_exited(node + "/MarginContainer/NinePatchRect")

func _click_input(event: InputEvent):
	if event.is_action_pressed("left_mouse_pressed"):
		accept_event()
		_ok_event()
