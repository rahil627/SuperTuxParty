extends TextureRect

const SPEED = 80;

func _process(delta):
	if margin_left >= 0:
		margin_left = -64
	if margin_top <= -64:
		margin_top = 0
	
	margin_left += SPEED * delta
	margin_top -= SPEED * delta