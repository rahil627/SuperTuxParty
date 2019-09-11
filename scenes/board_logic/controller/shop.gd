extends Control

signal shopping_completed

onready var controller = get_tree().get_nodes_in_group("Controller")[0]

func generate_shop_items(space, items: Array, icons: Array, cost: Array) ->\
		void:
	var buyable_item_info: Array = Global.item_loader.get_buyable_items()

	var buyable_items := []

	for item in buyable_item_info:
		buyable_items.append(Global.item_loader.get_item_path(item))

	for file in space.custom_items:
		buyable_items.erase(file)
		items.append(file)
		var instance = load(file).new()
		icons.append(instance.icon)
		cost.append(instance.item_cost)

	if items.size() > NodeBoard.MAX_STORE_SIZE:
		items.resize(NodeBoard.MAX_STORE_SIZE)

	var i: int = items.size()
	while i < NodeBoard.MAX_STORE_SIZE and buyable_items.size() != 0:
		var index: int = randi() % buyable_items.size()
		var random_item = buyable_items[index]
		buyable_items.remove(index)
		items.append(random_item)
		var instance = load(random_item).new()
		icons.append(instance.icon)
		cost.append(instance.item_cost)

		i = i + 1

func ai_do_shopping(player) -> void:
	var items := []
	var icons := []
	var cost := []
	generate_shop_items(player.space, items, icons, cost)

	# Index into the item array.
	var item_to_buy := -1
	for i in items.size():
		# Always keep enough money ready to buy a cake.
		# Buy the most expensive item that satisfies this criteria.
		if player.cookies - cost[i] >= controller.COOKIES_FOR_CAKE and\
				(item_to_buy == -1 or cost[item_to_buy] < cost[i]):
			item_to_buy = i

	if item_to_buy != null and player.give_item(load(items[item_to_buy]).new()):
		player.cookies -= cost[item_to_buy]

func open_shop(player) -> void:
	var items := []
	var icons := []
	var cost := []
	generate_shop_items(player.space, items, icons, cost)

	for i in NodeBoard.MAX_STORE_SIZE:
		var element = get_node("Item%d" % (i+1))
		var texture_button = element.get_node("Image")
		if texture_button.is_connected("pressed", self, "_on_shop_item"):
			texture_button.disconnect("pressed", self, "_on_shop_item")

		if i < items.size():
			texture_button.connect("pressed", self, "_on_shop_item",
					[player, items[i], cost[i]])
			texture_button.texture_normal = icons[i]
			if texture_button.is_connected("focus_entered", self,
					"_on_focus_entered"):
				texture_button.disconnect("focus_entered", self,
						"_on_focus_entered")
			if texture_button.is_connected("focus_exited", self,
					"_on_focus_exited"):
				texture_button.disconnect("focus_exited", self,
						"_on_focus_exited")
			if texture_button.is_connected("mouse_entered", self,
					"_on_mouse_entered"):
				texture_button.disconnect("mouse_entered", self,
						"_on_mouse_entered")
			if texture_button.is_connected("mouse_exited", self,
					"_on_mouse_exited"):
				texture_button.disconnect("mouse_exited", self,
						"_on_mouse_exited")
			if texture_button.is_connected("pressed", self, "_on_item_select"):
				texture_button.disconnect("pressed", self, "_on_item_select")

			texture_button.connect("focus_entered", self, "_on_focus_entered",
					[texture_button])
			texture_button.connect("focus_exited", self, "_on_focus_exited",
					[texture_button])
			texture_button.connect("mouse_entered", self, "_on_mouse_entered",
					[texture_button])
			texture_button.connect("mouse_exited", self, "_on_mouse_exited",
					[texture_button])

			texture_button.material.set_shader_param("enable_shader", false)

			element.get_node("Cost/Amount").text = var2str(cost[i])
			if player.cookies < cost[i]:
				element.get_node("Cost/Amount").add_color_override(
						"font_color", Color(1, 0, 0))
			else:
				element.get_node("Cost/Amount").add_color_override(
						"font_color", Color(1, 1, 1))
		else:
			texture_button.texture_normal = null
			element.get_node("Cost/Amount").text = ""

	$Item1/Image.grab_focus()
	show()


func _on_shop_item(player, item, cost: int) -> void:
	if player.cookies >= cost and player.give_item(load(item).new()):
		player.cookies -= cost
	elif player.cookies < cost:
		$Notification.dialog_text = tr("CONTEXT_NOTIFICATION_NOT_ENOUGH_COOKIES")
		# Make it visible or else Godot does not recalculate the size
		# Temporary until fixed in Godot.
		$Notification.show()

		$Notification.popup_centered()
	else:
		$Notification.dialog_text = tr("CONTEXT_NOTIFICATION_NOT_ENOUGH_SPACE")
		# Make it visible or else Godot does not recalculate the size
		# Temporary until fixed in Godot.
		$Notification.show()

		$Notification.popup_centered()

func _on_Shop_Back_pressed() -> void:
	hide()
	emit_signal("shopping_completed")

func _on_focus_entered(button) -> void:
	button.material.set_shader_param("enable_shader", true)

func _on_focus_exited(button) -> void:
	button.material.set_shader_param("enable_shader", false)

func _on_mouse_entered(button) -> void:
	button.material.set_shader_param("enable_shader", true)

func _on_mouse_exited(button) -> void:
	if not button.has_focus():
		button.material.set_shader_param("enable_shader", false)
