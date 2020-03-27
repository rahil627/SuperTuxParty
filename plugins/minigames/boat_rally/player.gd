extends Spatial

var player_id: int
var is_ai: bool

var paddle_cooldown := randf() if is_ai else 0.0

export var force_dir: Vector3
export var flip_paddle: bool

func _ready():
	$Model/AnimationPlayer.play("idle")
	if flip_paddle:
		$"Scene Root".rotation.y *= -1
		$"Scene Root".scale.x *= -1
		$"Scene Root".translation.x *= -1

func fire():
	if get_parent().fire(self.translation, force_dir):
		$Model/AnimationPlayer.play("punch")
		$Model/AnimationPlayer.queue("idle")
		$AnimationPlayer.play("paddle")
		paddle_cooldown = 1 if not is_ai else 2

func _process(delta):
	paddle_cooldown = max(0, paddle_cooldown - delta)
	if paddle_cooldown > 0:
		return
	
	if not is_ai:
		if Input.is_action_just_pressed("player%d_action1" % player_id):
			fire()
	else:
		var pos = get_parent().translation
		var rot = get_parent().rotation_degrees
		
		if (rot.y > 20 and force_dir.x > 0) or (rot.y < -20 and force_dir.x < 0):
			return
		
		var rocks = []
		for rock in get_tree().get_nodes_in_group("rock"):
			if rock.translation.z < pos.z + 10 and rock.translation.z > pos.z and abs(rock.translation.x - pos.x) < 6:
				rocks.append(rock)
		
		if len(rocks) == 0:
			fire()
			return
		
		for rock in rocks:
			if rock.translation.x - pos.x >= -0.1 and force_dir.x < 0:
				fire()
				return
			elif rock.translation.x - pos.x < -0.1 and force_dir.x > 0:
				fire()
				return
