tool
extends PopupPanel

signal selected(item)

func set_options(list: Array):
	list.sort()
	for child in $VBoxContainer/ScrollContainer/VBoxContainer.get_children():
		$VBoxContainer/ScrollContainer/VBoxContainer.remove_child(child)
		child.queue_free()
	for item in list:
		var button := Button.new()
		button.text = item
		button.connect("pressed", self, "_on_selected", [item])
		$VBoxContainer/ScrollContainer/VBoxContainer.add_child(button)

func _on_selected(item):
	emit_signal("selected", item)
	hide()

func _on_Close_pressed():
	emit_signal("selected", null)
	hide()
