extends Control

signal dialog_finished
signal dialog_option_taken(accepted)

const CLICK_SOUND = preload("res://assets/sounds/ui/rollover2.wav")
const SELECT_SOUND = preload("res://assets/sounds/ui/click1.wav")

var player_id: int

func _ready() -> void:
	hide()

func _gui_input(event: InputEvent) -> void:
	var is_action: bool = event.is_action_pressed("player%d_ok" % player_id)
	var is_mouse: bool = event.is_action_pressed("left_mouse_pressed")
	if (is_action or is_mouse) and visible:
		if has_focus():
			accept_event()
			hide()
			UISound.stream = CLICK_SOUND
			UISound.play()
			emit_signal("dialog_finished")
		elif $HBoxContainer/NinePatchRect/Buttons/Yes.has_focus():
			accept_event()
			hide()
			UISound.stream = CLICK_SOUND
			UISound.play()
			emit_signal("dialog_option_taken", true)
		elif $HBoxContainer/NinePatchRect/Buttons/No.has_focus():
			accept_event()
			hide()
			UISound.stream = CLICK_SOUND
			UISound.play()
			emit_signal("dialog_option_taken", false)

func show_dialog(speaker: String, texture: Texture, text: String, player_id: int) -> void:
	$HBoxContainer/TextureRect.texture = texture
	self.player_id = player_id
	show()
	grab_focus()
	$HBoxContainer/NinePatchRect/Name.text = speaker
	$HBoxContainer/NinePatchRect/MarginContainer/Text.bbcode_text = text

func show_accept_dialog(speaker: String, texture: Texture, text: String, player_id: int) -> void:
	$HBoxContainer/TextureRect.texture = texture
	self.player_id = player_id
	show()
	$HBoxContainer/NinePatchRect/Name.text = speaker
	$HBoxContainer/NinePatchRect/MarginContainer/Text.bbcode_text = text
	$HBoxContainer/NinePatchRect/Buttons.show()
	$HBoxContainer/NinePatchRect/Buttons/Yes.grab_focus()

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
