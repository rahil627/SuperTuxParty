extends Control

signal cake_shopping_completed(taken)

onready var controller = get_tree().get_nodes_in_group("Controller")[0]

var cookies_for_cake: int

func init(cookies_for_cake: int) -> void:
	$GetCake/Label.text = tr("CONTEXT_LABEL_BUY_CAKE") % cookies_for_cake
	self.cookies_for_cake = cookies_for_cake

func show_cake() -> void:
	$GetCake.show()

func _on_GetCake_pressed() -> void:
	$BuyCake/HSlider.max_value =\
			int(controller.players[controller.player_turn - 1].cookies
			/ cookies_for_cake)

	if $BuyCake/HSlider.max_value == 1:
		$BuyCake/HSlider.hide()
	else:
		$BuyCake/HSlider.show()

	$GetCake.hide()
	$BuyCake.show()

	$BuyCake/HSlider.value = $BuyCake/HSlider.max_value
	$BuyCake/Amount.text =\
			"x" + var2str(int($BuyCake/HSlider.max_value))

func _on_GetCake_abort() -> void:
	$GetCake.hide()

	emit_signal("cake_shopping_completed", false)

func _on_Buy_pressed() -> void:
	var amount := int($BuyCake/HSlider.value)

	var player = controller.players[controller.player_turn - 1]
	player.cookies -= cookies_for_cake * amount
	player.cakes += amount

	$BuyCake.hide()

	emit_signal("cake_shopping_completed", true)

func _on_Abort_pressed() -> void:
	$BuyCake.hide()
	$GetCake.show()

func _on_HSlider_value_changed(value: float) -> void:
	$BuyCake/Amount.text = "x" + str(int(value))

