extends Control

export(float) var countdown_time = 3
export(bool) var autostart = true

signal finish

var time_left
var timer_finished

func _force_animation_update(node):
	if node is AnimationPlayer:
		node.seek(0, true)

	for child in node.get_children():
		_force_animation_update(child)

func _ready():
	if autostart:
		start()

func start():
	# Force update all animations or they won't be shown properly if they were just started
	_force_animation_update(get_tree().root)

	timer_finished = false
	time_left = countdown_time
	get_tree().paused = true
	$Label.modulate = Color(1, 1, 1, 1)

func _is_paused():
	# Check if the pause menu is open
	for node in get_tree().get_nodes_in_group("pausemenu"):
		if node.paused:
			return true
	return false

func _process(delta):
	# Only let the timer run if the pause menu is not open
	if not timer_finished and not _is_paused():
		$Label.text = var2str(int(time_left) + 1)

		time_left = max(time_left - delta, 0)
		if time_left == 0:
			_on_Timer_timeout()

func _on_Timer_timeout():
	timer_finished = true
	$Label.text = tr("CONTEXT_LABEL_GO")
	$AnimationPlayer.play("fadeout")
	get_tree().paused = false

	emit_signal("finish")
