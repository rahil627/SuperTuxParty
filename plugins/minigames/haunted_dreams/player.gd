extends KinematicBody

const SPEED := 3

var player_id: int
var is_ai: bool

func _ready():
	$Model/AnimationPlayer.play("idle")

func _process(_delta):
	var dir: Vector3
	if not is_ai:
		dir.x = Input.get_action_strength("player%d_right" % player_id) - Input.get_action_strength("player%d_left" % player_id)
		dir.z = Input.get_action_strength("player%d_down" % player_id) - Input.get_action_strength("player%d_up" % player_id)
	else:
		var target
		var dist = INF
		for ghost in get_tree().get_nodes_in_group("ghost"):
			var ndist = (ghost.translation - self.translation).length_squared()
			if ghost.translation.length_squared() < 25 and dist > ndist:
				target = ghost
				dist = ndist
		
		if target:
			var array = Array($"..".get_simple_path(self.translation, target.translation))
			dir = (array[1] - self.translation).normalized() * SPEED
			dir.y = 0
	
	if dir.length_squared() > 0:
		dir = dir.normalized() * SPEED
		rotation.y = atan2(dir.x, dir.z)
		$Model/AnimationPlayer.play("run")
	else:
		$Model/AnimationPlayer.play("idle")
	
	move_and_slide(dir + Vector3(0, -1, 0))