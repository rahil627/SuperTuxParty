extends Control

signal shopping_completed

onready var controller = get_tree().get_nodes_in_group("Controller")[0]

var selected_item: Node

func _init():
	hide()
	Global.connect("language_changed", self, "_on_refresh_language")

func generate_shop_items(space) -> Array:
	var items := []
	var buyable_item_info: Array = PluginSystem.item_loader.get_buyable_items()

	var buyable_items := []

	for item in buyable_item_info:
		buyable_items.append(item)

	for file in space.custom_items:
		buyable_items.erase(file)
		items.append(file)

	if items.size() > NodeBoard.MAX_STORE_SIZE:
		items.resize(NodeBoard.MAX_STORE_SIZE)

	var i: int = items.size()
	while i < NodeBoard.MAX_STORE_SIZE and buyable_items.size() != 0:
		var index: int = randi() % buyable_items.size()
		var random_item = buyable_items[index]
		buyable_items.remove(index)
		items.append(random_item)

		i = i + 1
	
	return items

func ai_do_shopping(player) -> void:
	var items := generate_shop_items(player.space)

	# Index into the item array.
	var item_to_buy := -1
	var item_cost := 0
	for i in items.size():
		var cost = load(items[i]).new().item_cost
		# Always keep enough money ready to buy a cake.
		# Buy the most expensive item that satisfies this criteria.
		if player.cookies - cost >= controller.COOKIES_FOR_CAKE and\
				(item_to_buy == -1 or item_cost < cost):
			item_to_buy = i
			item_cost = cost

	if item_to_buy != -1 and player.give_item(load(items[item_to_buy]).new()):
		player.cookies -= item_cost

func open_shop(player) -> void:
	var items := generate_shop_items(player.space)

	for i in NodeBoard.MAX_STORE_SIZE:
		var element := $Items.get_child(i)
		element.player = player
		if i < items.size():
			element.item = items[i]
			element.show()
		else:
			element.hide()
			element.item = null

	$Items/Item1.select()
	show()

func _on_shop_item(player, item: Item) -> void:
	var cost = item.item_cost
	if player.cookies >= cost and player.give_item(item):
		player.cookies -= cost
	elif player.cookies < cost:
		$Notification.dialog_text = "CONTEXT_NOTIFICATION_NOT_ENOUGH_COOKIES"
		$Notification.popup_centered()
	else:
		$Notification.dialog_text = "CONTEXT_NOTIFICATION_NOT_ENOUGH_SPACE"
		$Notification.popup_centered()

func _on_show_description(text: String):
	$PanelContainer/VBoxContainer/RichTextLabel.text = tr(text)

func _on_refresh_language():
	if selected_item:
		selected_item.update_description()

func _on_Shop_Back_pressed() -> void:
	hide()
	emit_signal("shopping_completed")
